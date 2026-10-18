/// One detected object. Coordinates are normalized to the source image,
/// origin at the top left, each edge in the 0 to 1 range.
class Detection {
  const Detection({
    required this.label,
    required this.classId,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String label;
  final int classId;
  final double confidence;
  final double left;
  final double top;
  final double right;
  final double bottom;

  Detection copyWithBox({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    return Detection(
      label: label,
      classId: classId,
      confidence: confidence,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Detection &&
        other.label == label &&
        other.classId == classId &&
        other.confidence == confidence &&
        other.left == left &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom;
  }

  @override
  int get hashCode =>
      Object.hash(label, classId, confidence, left, top, right, bottom);
}

/// Detections from a single inference, plus the time spent inside the model
/// and its preprocessing on the inference isolate.
class DetectionResult {
  const DetectionResult({
    required this.detections,
    required this.inferenceTime,
  });

  final List<Detection> detections;
  final Duration inferenceTime;
}
