import 'dart:typed_data';

import 'package:on_device_vision/domain/detection_frame.dart';

/// BT.601 limited-range YUV to RGB. Exposed for unit tests.
({int r, int g, int b}) yuvToRgb(int y, int u, int v) {
  final int c = y - 16;
  final int d = u - 128;
  final int e = v - 128;
  return (
    r: _byte((298 * c + 409 * e + 128) >> 8),
    g: _byte((298 * c - 100 * d - 208 * e + 128) >> 8),
    b: _byte((298 * c + 516 * d + 128) >> 8),
  );
}

/// Nearest-neighbor sample of [frame] into a tightly packed RGB tensor of
/// [inputSize] x [inputSize]. Sampling and color conversion happen together
/// so a camera frame is not expanded into a full-resolution RGB buffer.
Uint8List modelInputFromFrame(DetectionFrame frame, {required int inputSize}) {
  if (inputSize <= 0) {
    throw ArgumentError.value(inputSize, 'inputSize', 'Must be positive.');
  }
  final Uint8List output = Uint8List(inputSize * inputSize * 3);
  switch (frame) {
    case RgbFrame():
      _sampleRgb(frame, output, inputSize);
    case Yuv420Frame():
      _sampleYuv420(frame, output, inputSize);
    case Nv21Frame():
      _sampleNv21(frame, output, inputSize);
    case BgraFrame():
      _sampleBgra(frame, output, inputSize);
  }
  return output;
}

void _sampleRgb(RgbFrame frame, Uint8List output, int inputSize) {
  for (var y = 0; y < inputSize; y++) {
    final int sy = y * frame.height ~/ inputSize;
    for (var x = 0; x < inputSize; x++) {
      final int sx = x * frame.width ~/ inputSize;
      final int source = (sy * frame.width + sx) * 3;
      final int dest = (y * inputSize + x) * 3;
      if (source + 2 >= frame.bytes.length) {
        continue;
      }
      output[dest] = frame.bytes[source];
      output[dest + 1] = frame.bytes[source + 1];
      output[dest + 2] = frame.bytes[source + 2];
    }
  }
}

void _sampleYuv420(Yuv420Frame frame, Uint8List output, int inputSize) {
  for (var y = 0; y < inputSize; y++) {
    final int sy = y * frame.height ~/ inputSize;
    for (var x = 0; x < inputSize; x++) {
      final int sx = x * frame.width ~/ inputSize;
      final int yIndex = sy * frame.yRowStride + sx;
      final int uvIndex =
          (sy ~/ 2) * frame.uvRowStride + (sx ~/ 2) * frame.uvPixelStride;
      final ({int r, int g, int b}) rgb = yuvToRgb(
        _at(frame.y, yIndex, 0),
        _at(frame.u, uvIndex, 128),
        _at(frame.v, uvIndex, 128),
      );
      _write(output, inputSize, x, y, rgb);
    }
  }
}

void _sampleNv21(Nv21Frame frame, Uint8List output, int inputSize) {
  for (var y = 0; y < inputSize; y++) {
    final int sy = y * frame.height ~/ inputSize;
    for (var x = 0; x < inputSize; x++) {
      final int sx = x * frame.width ~/ inputSize;
      final int yIndex = sy * frame.yRowStride + sx;
      final int vuIndex =
          (sy ~/ 2) * frame.vuRowStride + (sx ~/ 2) * frame.vuPixelStride;
      final ({int r, int g, int b}) rgb = yuvToRgb(
        _at(frame.y, yIndex, 0),
        _at(frame.vu, vuIndex + 1, 128),
        _at(frame.vu, vuIndex, 128),
      );
      _write(output, inputSize, x, y, rgb);
    }
  }
}

void _sampleBgra(BgraFrame frame, Uint8List output, int inputSize) {
  for (var y = 0; y < inputSize; y++) {
    final int sy = y * frame.height ~/ inputSize;
    for (var x = 0; x < inputSize; x++) {
      final int sx = x * frame.width ~/ inputSize;
      final int pixel = sy * frame.bytesPerRow + sx * 4;
      if (pixel + 2 >= frame.bytes.length) {
        continue;
      }
      _write(output, inputSize, x, y, (
        r: frame.bytes[pixel + 2],
        g: frame.bytes[pixel + 1],
        b: frame.bytes[pixel],
      ));
    }
  }
}

void _write(
  Uint8List output,
  int inputSize,
  int x,
  int y,
  ({int r, int g, int b}) rgb,
) {
  final int dest = (y * inputSize + x) * 3;
  output[dest] = rgb.r;
  output[dest + 1] = rgb.g;
  output[dest + 2] = rgb.b;
}

int _at(Uint8List plane, int index, int fallback) {
  if (index < 0 || index >= plane.length) {
    return fallback;
  }
  return plane[index];
}

int _byte(int value) {
  if (value < 0) {
    return 0;
  }
  if (value > 255) {
    return 255;
  }
  return value;
}
