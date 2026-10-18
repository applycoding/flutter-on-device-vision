import 'package:on_device_vision/domain/detection.dart';
import 'package:on_device_vision/domain/detection_frame.dart';
import 'package:on_device_vision/domain/detector.dart';
import 'package:on_device_vision/domain/model_spec.dart';

/// Scripted detector for unit and widget tests. It applies the same confidence
/// cutoff the TFLite path applies, and it records what the UI asked for.
class FakeObjectDetector implements ObjectDetector {
  FakeObjectDetector({this.detections = const <Detection>[]});

  List<Detection> detections;
  ModelSpec? loadedSpec;
  int detectCount = 0;
  double? lastThreshold;
  DetectionFrame? lastFrame;
  bool disposed = false;

  void setDetections(List<Detection> value) {
    detections = value;
  }

  @override
  Future<void> load(ModelSpec spec) async {
    loadedSpec = spec;
  }

  @override
  Future<DetectionResult> detect(
    DetectionFrame frame, {
    required double confidenceThreshold,
  }) async {
    detectCount += 1;
    lastThreshold = confidenceThreshold;
    lastFrame = frame;
    final List<Detection> kept = <Detection>[
      for (final Detection detection in detections)
        if (detection.confidence >= confidenceThreshold) detection,
    ];
    return DetectionResult(
      detections: kept,
      inferenceTime: const Duration(milliseconds: 12),
    );
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
