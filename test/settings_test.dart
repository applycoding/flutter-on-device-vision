import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_vision/domain/coco_labels.dart';
import 'package:on_device_vision/domain/model_spec.dart';
import 'package:on_device_vision/providers/providers.dart';

void main() {
  test('label lists match the COCO exports', () {
    expect(cocoLabelMap, hasLength(91));
    expect(cocoLabelMap[1], 'person');
    expect(cocoLabels80, hasLength(80));
    expect(cocoLabels80.first, 'person');
    expect(ModelSpec.efficientDetLite0.inputSize, 320);
    expect(ModelSpec.ssdMobileNet.inputSize, 300);
  });

  test('settings notifier clamps confidence and switches model', () {
    final ProviderContainer container = ProviderContainer(
      retry: (int retryCount, Object error) => null,
    );
    addTearDown(container.dispose);

    expect(container.read(settingsProvider).confidenceThreshold, 0.5);
    container.read(settingsProvider.notifier).setConfidence(0.99);
    expect(container.read(settingsProvider).confidenceThreshold, 0.95);
    container
        .read(settingsProvider.notifier)
        .selectModel(ModelChoice.efficientDetLite0);
    expect(container.read(settingsProvider).spec, ModelSpec.efficientDetLite0);
  });
}
