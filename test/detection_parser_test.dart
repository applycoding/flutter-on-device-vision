import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_vision/data/detection_parser.dart';
import 'package:on_device_vision/domain/coco_labels.dart';
import 'package:on_device_vision/domain/detection.dart';

void main() {
  test('keeps boxes above the threshold and maps SSD labels', () {
    final List<Detection> detections = parseDetections(
      boxes: <double>[0.1, 0.2, 0.5, 0.6, -0.2, 0.0, 1.2, 0.4],
      classes: <double>[0, 2],
      scores: <double>[0.91, 0.2],
      count: 2,
      confidenceThreshold: 0.5,
      labelOffset: 1,
      labels: cocoLabelMap,
    );

    expect(detections, hasLength(1));
    expect(detections.single.label, 'person');
    expect(detections.single.classId, 0);
    expect(detections.single.left, 0.2);
    expect(detections.single.top, 0.1);
    expect(detections.single.right, 0.6);
    expect(detections.single.bottom, 0.5);
  });

  test('clamps boxes and honors the model detection count', () {
    final List<Detection> detections = parseDetections(
      boxes: <double>[-0.2, 0.0, 1.4, 0.4, 0.1, 0.1, 0.2, 0.2],
      classes: <double>[0, 1],
      scores: <double>[0.8, 0.9],
      count: 1,
      confidenceThreshold: 0.1,
      labelOffset: 0,
      labels: cocoLabels80,
    );

    expect(detections, hasLength(1));
    expect(detections.single.label, 'person');
    expect(detections.single.top, 0);
    expect(detections.single.bottom, 1);
    expect(detections.single.right, 0.4);
  });

  test('uses object when the class id is outside the label list', () {
    final List<Detection> detections = parseDetections(
      boxes: <double>[0, 0, 1, 1],
      classes: <double>[400],
      scores: <double>[0.7],
      count: 1,
      confidenceThreshold: 0.5,
      labelOffset: 0,
      labels: cocoLabels80,
    );

    expect(detections.single.label, 'object');
  });
}
