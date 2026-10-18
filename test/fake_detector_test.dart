import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_vision/data/fake_object_detector.dart';
import 'package:on_device_vision/domain/detection.dart';
import 'package:on_device_vision/domain/detection_frame.dart';
import 'package:on_device_vision/domain/model_spec.dart';

void main() {
  const Detection person = Detection(
    label: 'person',
    classId: 0,
    confidence: 0.82,
    left: 0.1,
    top: 0.1,
    right: 0.4,
    bottom: 0.8,
  );
  const Detection cup = Detection(
    label: 'cup',
    classId: 41,
    confidence: 0.3,
    left: 0.5,
    top: 0.5,
    right: 0.7,
    bottom: 0.9,
  );

  test('filters scripted detections by confidence', () async {
    final FakeObjectDetector detector = FakeObjectDetector(
      detections: const <Detection>[person, cup],
    );
    await detector.load(ModelSpec.ssdMobileNet);
    final result = await detector.detect(
      RgbFrame(bytes: Uint8List(0), width: 1, height: 1),
      confidenceThreshold: 0.5,
    );

    expect(detector.loadedSpec, ModelSpec.ssdMobileNet);
    expect(detector.detectCount, 1);
    expect(detector.lastThreshold, 0.5);
    expect(result.detections, const <Detection>[person]);
    expect(result.inferenceTime, const Duration(milliseconds: 12));

    await detector.dispose();
    expect(detector.disposed, isTrue);
  });
}
