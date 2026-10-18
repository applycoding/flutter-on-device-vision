import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_device_vision/domain/decoded_image.dart';
import 'package:on_device_vision/domain/detection.dart';
import 'package:on_device_vision/domain/detection_frame.dart';
import 'package:on_device_vision/domain/model_spec.dart';
import 'package:on_device_vision/providers/providers.dart';
import 'package:on_device_vision/ui/detection_overlay.dart';
import 'package:on_device_vision/ui/theme.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  DecodedImage? _image;
  List<Detection> _detections = const <Detection>[];
  Duration? _inference;
  String? _error;
  var _busy = false;
  var _generation = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (
      DetectionSettings? previous,
      DetectionSettings next,
    ) {
      final DecodedImage? image = _image;
      if (image != null && previous != next) {
        unawaited(Future<void>.microtask(() => _detect(image)));
      }
    });

    final AsyncValue<ModelSpec> ready = ref.watch(detectorReadyProvider);
    return ColoredBox(
      color: visionInk,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Gallery',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(child: _body(ready)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                key: const Key('choose-photo'),
                onPressed: _busy ? null : _pick,
                child: Text(
                  _image == null ? 'Choose a photo' : 'Choose another',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AsyncValue<ModelSpec> ready) {
    if (ready.hasError) {
      return _Status(ready.error.toString());
    }
    final String? error = _error;
    if (error != null) {
      return _Status(error);
    }
    final DecodedImage? image = _image;
    if (image == null) {
      return const _Status(
        'Pick a photo from your library. Detection stays on device.',
      );
    }
    if (_busy && _detections.isEmpty) {
      return const _Status('Running detection');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final FittedSizes fitted = applyBoxFit(
            BoxFit.contain,
            Size(image.width.toDouble(), image.height.toDouble()),
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          final Rect destination = Alignment.center.inscribe(
            fitted.destination,
            Offset.zero & Size(constraints.maxWidth, constraints.maxHeight),
          );
          final bool nothing =
              !_busy && _detections.isEmpty && _inference != null;
          return Stack(
            children: <Widget>[
              Positioned.fromRect(
                rect: destination,
                child: DetectionOverlay(
                  detections: _detections,
                  inferenceTime: _inference,
                  modelName: ref.watch(settingsProvider).spec.displayName,
                  child: Image.memory(
                    image.pngBytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              if (nothing)
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: _Status('No objects above the confidence threshold.'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pick() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final Uint8List? bytes = await ref
          .read(galleryPickerProvider)
          .pickImageBytes();
      if (!mounted) {
        return;
      }
      if (bytes == null) {
        setState(() => _busy = false);
        return;
      }
      final DecodedImage? decoded = await ref
          .read(imageDecoderProvider)
          .decode(bytes);
      if (!mounted) {
        return;
      }
      if (decoded == null) {
        setState(() {
          _busy = false;
          _error = 'Could not read that image.';
          _image = null;
        });
        return;
      }
      setState(() => _image = decoded);
      await _detect(decoded);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = 'Could not open that photo. $error';
      });
    }
  }

  Future<void> _detect(DecodedImage image) async {
    final int generation = ++_generation;
    setState(() => _busy = true);
    try {
      await ref.read(detectorReadyProvider.future);
      final DetectionResult result = await ref
          .read(objectDetectorProvider)
          .detect(
            RgbFrame(
              bytes: image.rgb,
              width: image.width,
              height: image.height,
            ),
            confidenceThreshold: ref.read(settingsProvider).confidenceThreshold,
          );
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _detections = result.detections;
        _inference = result.inferenceTime;
        _busy = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }
}

class _Status extends StatelessWidget {
  const _Status(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: visionMuted, height: 1.4),
        ),
      ),
    );
  }
}
