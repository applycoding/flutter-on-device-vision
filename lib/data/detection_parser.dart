import 'package:on_device_vision/domain/detection.dart';

/// Reads the standard TFLite detection head.
///
/// [boxes] is packed ymin, xmin, ymax, xmax. [count] is the model's own
/// detection count and may be smaller than [scores].
List<Detection> parseDetections({
  required List<double> boxes,
  required List<double> classes,
  required List<double> scores,
  required int count,
  required double confidenceThreshold,
  required int labelOffset,
  required List<String> labels,
}) {
  final int available = scores.length < classes.length
      ? scores.length
      : classes.length;
  final int boxCapacity = boxes.length ~/ 4;
  final int limit = _clampCount(
    count,
    available < boxCapacity ? available : boxCapacity,
  );
  final List<Detection> detections = <Detection>[];
  for (var index = 0; index < limit; index++) {
    final double score = scores[index];
    if (score < confidenceThreshold) {
      continue;
    }
    final int boxIndex = index * 4;
    final int classId = classes[index].round();
    detections.add(
      Detection(
        label: _labelFor(classId + labelOffset, labels),
        classId: classId,
        confidence: score,
        left: _unit(boxes[boxIndex + 1]),
        top: _unit(boxes[boxIndex]),
        right: _unit(boxes[boxIndex + 3]),
        bottom: _unit(boxes[boxIndex + 2]),
      ),
    );
  }
  detections.sort(
    (Detection a, Detection b) => b.confidence.compareTo(a.confidence),
  );
  return detections;
}

int _clampCount(int count, int max) {
  if (count < 0) {
    return 0;
  }
  if (count > max) {
    return max;
  }
  return count;
}

double _unit(double value) {
  if (value < 0) {
    return 0;
  }
  if (value > 1) {
    return 1;
  }
  return value;
}

String _labelFor(int index, List<String> labels) {
  if (index < 0 || index >= labels.length) {
    return 'object';
  }
  final String label = labels[index];
  if (label == 'background' || label.isEmpty) {
    return 'object';
  }
  return label;
}
