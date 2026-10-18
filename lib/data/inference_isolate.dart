import 'dart:isolate';
import 'dart:typed_data';

import 'package:on_device_vision/data/detection_parser.dart';
import 'package:on_device_vision/data/frame_converter.dart';
import 'package:on_device_vision/domain/detection.dart';
import 'package:on_device_vision/domain/detection_frame.dart';
import 'package:on_device_vision/domain/model_spec.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

enum IsolateOp { load, detect, dispose }

/// Message sent to the inference isolate. Fields are plain data so they can
/// cross the isolate boundary.
class IsolateRequest {
  const IsolateRequest({
    required this.id,
    required this.op,
    this.modelBytes,
    this.spec,
    this.frame,
    this.confidenceThreshold,
  });

  final int id;
  final IsolateOp op;
  final Uint8List? modelBytes;
  final ModelSpec? spec;
  final DetectionFrame? frame;
  final double? confidenceThreshold;
}

class IsolateResponse {
  const IsolateResponse({required this.id, this.result, this.error});

  final int id;
  final DetectionResult? result;
  final String? error;
}

/// Owns the TFLite interpreter. The UI isolate only sends frames and paints.
void inferenceIsolateMain(SendPort toMain) {
  final ReceivePort incoming = ReceivePort();
  toMain.send(incoming.sendPort);
  Interpreter? interpreter;
  ModelSpec? spec;

  incoming.listen((Object? message) {
    if (message is! IsolateRequest) {
      return;
    }
    try {
      switch (message.op) {
        case IsolateOp.load:
          interpreter?.close();
          final InterpreterOptions options = InterpreterOptions()..threads = 2;
          interpreter = Interpreter.fromBuffer(
            message.modelBytes!,
            options: options,
          );
          spec = message.spec;
          toMain.send(IsolateResponse(id: message.id));
        case IsolateOp.detect:
          final DetectionResult result = _detect(
            interpreter: interpreter!,
            spec: spec!,
            frame: message.frame!,
            confidenceThreshold: message.confidenceThreshold!,
          );
          toMain.send(IsolateResponse(id: message.id, result: result));
        case IsolateOp.dispose:
          interpreter?.close();
          interpreter = null;
          spec = null;
          toMain.send(IsolateResponse(id: message.id));
      }
    } catch (error) {
      toMain.send(IsolateResponse(id: message.id, error: error.toString()));
    }
  });
}

DetectionResult _detect({
  required Interpreter interpreter,
  required ModelSpec spec,
  required DetectionFrame frame,
  required double confidenceThreshold,
}) {
  final Stopwatch stopwatch = Stopwatch()..start();
  final Uint8List rgb = modelInputFromFrame(frame, inputSize: spec.inputSize);
  final Tensor input = interpreter.getInputTensor(0);
  input.data = _inputBytes(rgb, input.type);
  interpreter.invoke();

  final List<Tensor> outputs = interpreter.getOutputTensors();
  if (outputs.length < 3) {
    throw StateError(
      'Expected boxes, classes, and scores outputs, found ${outputs.length}.',
    );
  }
  final List<int> boxShape = outputs[0].shape;
  if (boxShape.isEmpty || boxShape.last != 4) {
    throw StateError('Output 0 is not a box tensor. Shape was $boxShape.');
  }
  final Float32List boxes = _floats(outputs[0]);
  final Float32List classes = _floats(outputs[1]);
  final Float32List scores = _floats(outputs[2]);
  final int count = outputs.length >= 4
      ? _floats(outputs[3]).first.round()
      : scores.length;
  stopwatch.stop();
  return DetectionResult(
    detections: parseDetections(
      boxes: boxes,
      classes: classes,
      scores: scores,
      count: count,
      confidenceThreshold: confidenceThreshold,
      labelOffset: spec.labelOffset,
      labels: spec.labels,
    ),
    inferenceTime: stopwatch.elapsed,
  );
}

Uint8List _inputBytes(Uint8List rgb, TensorType type) {
  switch (type) {
    case TensorType.uint8:
      return rgb;
    case TensorType.float32:
      final Float32List floats = Float32List(rgb.length);
      for (var index = 0; index < rgb.length; index++) {
        floats[index] = (rgb[index] - 127.5) / 127.5;
      }
      return floats.buffer.asUint8List(
        floats.offsetInBytes,
        floats.lengthInBytes,
      );
    case TensorType.noType:
    case TensorType.int32:
    case TensorType.int64:
    case TensorType.string:
    case TensorType.boolean:
    case TensorType.int16:
    case TensorType.complex64:
    case TensorType.int8:
    case TensorType.float16:
    case TensorType.float64:
    case TensorType.complex128:
    case TensorType.uint64:
    case TensorType.resource:
    case TensorType.variant:
    case TensorType.uint32:
    case TensorType.uint16:
    case TensorType.int4:
      throw StateError('Unsupported model input type $type.');
  }
}

Float32List _floats(Tensor tensor) {
  if (tensor.type != TensorType.float32) {
    throw StateError(
      'Expected float32 output "${tensor.name}", found ${tensor.type}.',
    );
  }
  final Uint8List bytes = Uint8List.fromList(tensor.data);
  return bytes.buffer.asFloat32List(0, bytes.lengthInBytes ~/ 4);
}
