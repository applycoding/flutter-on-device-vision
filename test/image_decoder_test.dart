import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:on_device_vision/data/image_decoding.dart';

void main() {
  test('decodes an oriented png into rgb', () {
    final img.Image picture = img.Image(width: 2, height: 2);
    img.fill(picture, color: img.ColorRgb8(200, 10, 20));
    final Uint8List png = Uint8List.fromList(img.encodePng(picture));

    final decoded = decodeForDetection(png);

    expect(decoded, isNotNull);
    expect(decoded!.width, 2);
    expect(decoded.height, 2);
    expect(decoded.rgb, hasLength(12));
    expect(decoded.rgb[0], 200);
    expect(decoded.rgb[1], 10);
    expect(decoded.rgb[2], 20);
    expect(decoded.pngBytes, isNotEmpty);
  });

  test('returns null for bytes that are not an image', () {
    expect(decodeForDetection(Uint8List.fromList(<int>[1, 2, 3, 4])), isNull);
  });
}
