import 'package:on_device_vision/domain/detection.dart';
import 'package:on_device_vision/domain/detection_frame.dart';
import 'package:on_device_vision/domain/model_spec.dart';

/// Runs object detection. The app binds a TFLite implementation.
/// Tests bind [FakeObjectDetector] instead, so they never load native code.
abstract interface class ObjectDetector {
  Future<void> load(ModelSpec spec);

  Future<DetectionResult> detect(
    DetectionFrame frame, {
    required double confidenceThreshold,
  });

  Future<void> dispose();
}
