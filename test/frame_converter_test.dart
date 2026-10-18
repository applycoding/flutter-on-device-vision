import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_vision/data/frame_converter.dart';
import 'package:on_device_vision/domain/detection_frame.dart';

void main() {
  test('neutral yuv is mid gray', () {
    final ({int r, int g, int b}) rgb = yuvToRgb(128, 128, 128);
    expect(rgb.r, 130);
    expect(rgb.g, 130);
    expect(rgb.b, 130);
  });

  test('bgra samples into rgb model input', () {
    final Uint8List input = modelInputFromFrame(
      BgraFrame(
        bytes: Uint8List.fromList(<int>[10, 20, 30, 255]),
        width: 1,
        height: 1,
        bytesPerRow: 4,
      ),
      inputSize: 1,
    );

    expect(input, <int>[30, 20, 10]);
  });

  test('yuv420 identity sample uses the chroma planes', () {
    final Uint8List plane = Uint8List.fromList(<int>[128]);
    final Uint8List input = modelInputFromFrame(
      Yuv420Frame(
        y: plane,
        u: plane,
        v: plane,
        width: 1,
        height: 1,
        yRowStride: 1,
        uvRowStride: 1,
        uvPixelStride: 1,
      ),
      inputSize: 1,
    );

    expect(input, <int>[130, 130, 130]);
  });

  test('rgb nearest resize keeps the top-left pixel for a 1x1 output', () {
    final Uint8List input = modelInputFromFrame(
      RgbFrame(
        bytes: Uint8List.fromList(<int>[9, 8, 7, 1, 2, 3, 4, 5, 6, 0, 0, 0]),
        width: 2,
        height: 2,
      ),
      inputSize: 1,
    );

    expect(input, <int>[9, 8, 7]);
  });
}
