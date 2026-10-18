import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_device_vision/data/gallery_picker_impl.dart';
import 'package:on_device_vision/data/image_decoding.dart';
import 'package:on_device_vision/domain/decoded_image.dart';
import 'package:on_device_vision/domain/detector.dart';
import 'package:on_device_vision/domain/gallery_picker.dart';
import 'package:on_device_vision/domain/model_spec.dart';

/// Overridden in `main.dart` with the TFLite detector. Tests override it
/// with the fake detector. Keeping the default free of TFLite means widget
/// tests never load the native library.
final Provider<ObjectDetector> objectDetectorProvider =
    Provider<ObjectDetector>(
      (Ref ref) => throw StateError(
        'objectDetectorProvider must be overridden with a detector.',
      ),
    );

final Provider<GalleryPicker> galleryPickerProvider = Provider<GalleryPicker>(
  (Ref ref) => ImagePickerGalleryPicker(),
);

final Provider<ImageDecoder> imageDecoderProvider = Provider<ImageDecoder>(
  (Ref ref) => const ComputeImageDecoder(),
);

class DetectionSettings {
  const DetectionSettings({
    required this.confidenceThreshold,
    required this.model,
  });

  final double confidenceThreshold;
  final ModelChoice model;

  ModelSpec get spec => ModelSpec.forChoice(model);

  DetectionSettings copyWith({
    double? confidenceThreshold,
    ModelChoice? model,
  }) {
    return DetectionSettings(
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      model: model ?? this.model,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DetectionSettings &&
        other.confidenceThreshold == confidenceThreshold &&
        other.model == model;
  }

  @override
  int get hashCode => Object.hash(confidenceThreshold, model);
}

class SettingsNotifier extends Notifier<DetectionSettings> {
  @override
  DetectionSettings build() {
    return const DetectionSettings(
      confidenceThreshold: 0.5,
      model: ModelChoice.ssdMobileNet,
    );
  }

  void setConfidence(double value) {
    final double clamped = value.clamp(0.05, 0.95).toDouble();
    state = state.copyWith(confidenceThreshold: clamped);
  }

  void selectModel(ModelChoice model) {
    state = state.copyWith(model: model);
  }
}

final NotifierProvider<SettingsNotifier, DetectionSettings> settingsProvider =
    NotifierProvider<SettingsNotifier, DetectionSettings>(SettingsNotifier.new);

/// Loads the selected model once, and again when the choice changes.
final FutureProvider<ModelSpec> detectorReadyProvider =
    FutureProvider<ModelSpec>((Ref ref) async {
      final ModelSpec spec = ref.watch(
        settingsProvider.select((DetectionSettings settings) => settings.spec),
      );
      await ref.watch(objectDetectorProvider).load(spec);
      return spec;
    });
