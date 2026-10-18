import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:on_device_vision/data/inference_isolate.dart';
import 'package:on_device_vision/domain/detection.dart';
import 'package:on_device_vision/domain/detection_frame.dart';
import 'package:on_device_vision/domain/detector.dart';
import 'package:on_device_vision/domain/model_spec.dart';

/// Raised when a model asset is missing. Run `tool/download_models.sh`.
class ModelNotBundledException implements Exception {
  ModelNotBundledException(this.spec, {this.cause});

  final ModelSpec spec;
  final Object? cause;

  @override
  String toString() {
    return 'Model file ${spec.assetPath} is not bundled. '
        'Run tool/download_models.sh, then rebuild the app.';
  }
}

/// [ObjectDetector] that runs TFLite on a long-lived background isolate.
class TfliteObjectDetector implements ObjectDetector {
  Isolate? _isolate;
  SendPort? _toWorker;
  ReceivePort? _fromWorker;
  ReceivePort? _errors;
  final Map<int, Completer<IsolateResponse>> _pending =
      <int, Completer<IsolateResponse>>{};
  var _nextId = 0;
  Future<void> _tail = Future<void>.value();
  var _closed = false;

  @override
  Future<void> load(ModelSpec spec) async {
    final Uint8List bytes = await _loadAsset(spec);
    final IsolateResponse response = await _rpc(
      IsolateRequest(id: 0, op: IsolateOp.load, modelBytes: bytes, spec: spec),
    );
    _throwIfError(response);
  }

  @override
  Future<DetectionResult> detect(
    DetectionFrame frame, {
    required double confidenceThreshold,
  }) async {
    final IsolateResponse response = await _rpc(
      IsolateRequest(
        id: 0,
        op: IsolateOp.detect,
        frame: frame,
        confidenceThreshold: confidenceThreshold,
      ),
    );
    _throwIfError(response);
    final DetectionResult? result = response.result;
    if (result == null) {
      throw StateError('Inference finished without a result.');
    }
    return result;
  }

  @override
  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;
    if (_isolate != null) {
      try {
        await _rpc(const IsolateRequest(id: 0, op: IsolateOp.dispose))
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        // The worker may already have stopped.
      }
    }
    _isolate?.kill(priority: Isolate.immediate);
    _fromWorker?.close();
    _errors?.close();
    _isolate = null;
    _toWorker = null;
  }

  Future<Uint8List> _loadAsset(ModelSpec spec) async {
    try {
      final ByteData data = await rootBundle.load(spec.assetPath);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (error) {
      throw ModelNotBundledException(spec, cause: error);
    }
  }

  Future<IsolateResponse> _rpc(IsolateRequest request) {
    final Completer<IsolateResponse> done = Completer<IsolateResponse>();
    _tail = _tail.then((_) async {
      try {
        done.complete(await _roundTrip(request));
      } catch (error, stackTrace) {
        if (!done.isCompleted) {
          done.completeError(error, stackTrace);
        }
      }
    });
    return done.future;
  }

  Future<IsolateResponse> _roundTrip(IsolateRequest request) async {
    if (_closed && request.op != IsolateOp.dispose) {
      throw StateError('Detector is disposed.');
    }
    final SendPort send = await _ensureWorker();
    final int id = _nextId++;
    final Completer<IsolateResponse> pending = Completer<IsolateResponse>();
    _pending[id] = pending;
    send.send(
      IsolateRequest(
        id: id,
        op: request.op,
        modelBytes: request.modelBytes,
        spec: request.spec,
        frame: request.frame,
        confidenceThreshold: request.confidenceThreshold,
      ),
    );
    return pending.future;
  }

  Future<SendPort> _ensureWorker() async {
    final SendPort? existing = _toWorker;
    if (existing != null) {
      return existing;
    }
    final ReceivePort incoming = ReceivePort();
    final ReceivePort errors = ReceivePort();
    _fromWorker = incoming;
    _errors = errors;
    _isolate = await Isolate.spawn(
      inferenceIsolateMain,
      incoming.sendPort,
      onError: errors.sendPort,
      debugName: 'tflite-inference',
    );
    final Completer<SendPort> ready = Completer<SendPort>();
    incoming.listen((Object? message) {
      if (message is SendPort) {
        _toWorker = message;
        if (!ready.isCompleted) {
          ready.complete(message);
        }
        return;
      }
      if (message is IsolateResponse) {
        _pending.remove(message.id)?.complete(message);
      }
    });
    errors.listen((Object? error) {
      final StateError failure = StateError('Inference isolate failed: $error');
      for (final Completer<IsolateResponse> pending in _pending.values) {
        if (!pending.isCompleted) {
          pending.completeError(failure);
        }
      }
      _pending.clear();
      _toWorker = null;
    });
    return ready.future;
  }

  void _throwIfError(IsolateResponse response) {
    final String? error = response.error;
    if (error != null) {
      throw StateError(error);
    }
  }
}
