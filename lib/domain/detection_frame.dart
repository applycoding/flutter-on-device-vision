import 'dart:typed_data';

/// Pixels handed to a detector. The heavy conversion into model input happens
/// inside the implementation, which for TFLite is a background isolate.
sealed class DetectionFrame {
  const DetectionFrame();
}

/// Tightly packed RGB, 3 bytes per pixel, row major.
class RgbFrame extends DetectionFrame {
  const RgbFrame({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Android-style YUV420 with separate U and V planes.
class Yuv420Frame extends DetectionFrame {
  const Yuv420Frame({
    required this.y,
    required this.u,
    required this.v,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
  });

  final Uint8List y;
  final Uint8List u;
  final Uint8List v;
  final int width;
  final int height;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;
}

/// NV21: full-resolution Y plus interleaved VU chroma.
class Nv21Frame extends DetectionFrame {
  const Nv21Frame({
    required this.y,
    required this.vu,
    required this.width,
    required this.height,
    required this.yRowStride,
    required this.vuRowStride,
    required this.vuPixelStride,
  });

  final Uint8List y;
  final Uint8List vu;
  final int width;
  final int height;
  final int yRowStride;
  final int vuRowStride;
  final int vuPixelStride;
}

/// iOS camera buffers are typically BGRA with a row stride.
class BgraFrame extends DetectionFrame {
  const BgraFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;
}
