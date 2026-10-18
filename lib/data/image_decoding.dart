import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:on_device_vision/domain/decoded_image.dart';

const int _maxEdge = 1280;

/// Decodes, bakes EXIF orientation, and caps the long edge at 1280 px so
/// gallery inference and the preview share one bitmap.
DecodedImage? decodeForDetection(Uint8List bytes) {
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return null;
  }
  final img.Image oriented = img.bakeOrientation(decoded);
  final img.Image sized = _limitSize(oriented);
  final Uint8List rgb = Uint8List(sized.width * sized.height * 3);
  var offset = 0;
  for (var y = 0; y < sized.height; y++) {
    for (var x = 0; x < sized.width; x++) {
      final img.Pixel pixel = sized.getPixel(x, y);
      rgb[offset++] = pixel.r.toInt();
      rgb[offset++] = pixel.g.toInt();
      rgb[offset++] = pixel.b.toInt();
    }
  }
  return DecodedImage(
    pngBytes: Uint8List.fromList(img.encodePng(sized)),
    rgb: rgb,
    width: sized.width,
    height: sized.height,
  );
}

img.Image _limitSize(img.Image source) {
  final int edge = math.max(source.width, source.height);
  if (edge <= _maxEdge) {
    return source;
  }
  final double scale = _maxEdge / edge;
  return img.copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
    interpolation: img.Interpolation.linear,
  );
}

/// Decodes off the UI isolate. Tests override [ImageDecoder] with a sync fake.
class ComputeImageDecoder implements ImageDecoder {
  const ComputeImageDecoder();

  @override
  Future<DecodedImage?> decode(Uint8List bytes) {
    return compute(decodeForDetection, bytes);
  }
}

/// In-process decoder used by widget tests.
class SyncImageDecoder implements ImageDecoder {
  const SyncImageDecoder();

  @override
  Future<DecodedImage?> decode(Uint8List bytes) async {
    return decodeForDetection(bytes);
  }
}
