import 'package:on_device_vision/domain/coco_labels.dart';

/// Which bundled detector the settings screen can select.
enum ModelChoice { ssdMobileNet, efficientDetLite0 }

/// Static description of a TFLite object detector.
///
/// Both bundled models use the common detection head:
/// boxes `[1, N, 4]` as ymin, xmin, ymax, xmax, then classes, scores, and
/// a detection count. SSD class ids are offset by one into [cocoLabelMap]
/// (the export treats index 0 as background). EfficientDet-Lite0 class ids
/// index [cocoLabels80] directly.
class ModelSpec {
  const ModelSpec({
    required this.choice,
    required this.displayName,
    required this.summary,
    required this.assetPath,
    required this.inputSize,
    required this.labelOffset,
    required this.labels,
  });

  final ModelChoice choice;
  final String displayName;
  final String summary;
  final String assetPath;
  final int inputSize;
  final int labelOffset;
  final List<String> labels;

  static const ModelSpec ssdMobileNet = ModelSpec(
    choice: ModelChoice.ssdMobileNet,
    displayName: 'SSD MobileNet V1',
    summary: 'Quantized COCO SSD at 300 input. The lighter of the two models.',
    assetPath: 'assets/models/ssd_mobilenet_v1_coco.tflite',
    inputSize: 300,
    labelOffset: 1,
    labels: cocoLabelMap,
  );

  static const ModelSpec efficientDetLite0 = ModelSpec(
    choice: ModelChoice.efficientDetLite0,
    displayName: 'EfficientDet-Lite0',
    summary: 'COCO EfficientDet-Lite0 at 320 input. Slightly heavier.',
    assetPath: 'assets/models/efficientdet_lite0.tflite',
    inputSize: 320,
    labelOffset: 0,
    labels: cocoLabels80,
  );

  static ModelSpec forChoice(ModelChoice choice) {
    switch (choice) {
      case ModelChoice.ssdMobileNet:
        return ssdMobileNet;
      case ModelChoice.efficientDetLite0:
        return efficientDetLite0;
    }
  }
}
