import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_vision/domain/detection.dart';
import 'package:on_device_vision/domain/preview_mapping.dart';

void main() {
  const Detection box = Detection(
    label: 'cup',
    classId: 41,
    confidence: 0.8,
    left: 0,
    top: 0,
    right: 0.2,
    bottom: 0.4,
  );

  test('back camera portrait compensation is the sensor angle', () {
    expect(
      previewRotationDegrees(
        sensorOrientation: 90,
        orientation: CaptureOrientation.portraitUp,
        frontCamera: false,
      ),
      90,
    );
    expect(
      previewRotationDegrees(
        sensorOrientation: 270,
        orientation: CaptureOrientation.portraitUp,
        frontCamera: true,
      ),
      270,
    );
  });

  test('90 degree rotation and front-camera mirror', () {
    final Detection rotated = mapDetectionToPreview(
      box,
      rotationDegrees: 90,
      mirrorHorizontally: false,
    );
    expect(rotated.left, closeTo(0.6, 0.0001));
    expect(rotated.top, closeTo(0, 0.0001));
    expect(rotated.right, closeTo(1, 0.0001));
    expect(rotated.bottom, closeTo(0.2, 0.0001));

    final Detection mirrored = mapDetectionToPreview(
      box,
      rotationDegrees: 90,
      mirrorHorizontally: true,
    );
    expect(mirrored.left, closeTo(0, 0.0001));
    expect(mirrored.right, closeTo(0.4, 0.0001));
    expect(mirrored.top, closeTo(0, 0.0001));
    expect(mirrored.bottom, closeTo(0.2, 0.0001));
  });
}
