import 'dart:typed_data';

/// An oriented bitmap ready to display and to run through a detector.
class DecodedImage {
  const DecodedImage({
    required this.pngBytes,
    required this.rgb,
    required this.width,
    required this.height,
  });

  final Uint8List pngBytes;
  final Uint8List rgb;
  final int width;
  final int height;
}

/// Turns picked-file bytes into an oriented RGB image.
abstract interface class ImageDecoder {
  Future<DecodedImage?> decode(Uint8List bytes);
}
