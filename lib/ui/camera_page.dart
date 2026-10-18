import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_device_vision/data/camera_frame.dart';
import 'package:on_device_vision/domain/detection.dart';
import 'package:on_device_vision/domain/detection_frame.dart';
import 'package:on_device_vision/domain/model_spec.dart';
import 'package:on_device_vision/domain/preview_mapping.dart';
import 'package:on_device_vision/providers/providers.dart';
import 'package:on_device_vision/ui/detection_overlay.dart';
import 'package:on_device_vision/ui/theme.dart';

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  CameraController? _controller;
  String? _error;
  var _opening = true;
  var _busy = false;
  List<Detection> _detections = const <Detection>[];
  Duration? _inference;
  double? _fps;
  DeviceOrientation? _orientation;
  final List<DateTime> _frames = <DateTime>[];

  @override
  void initState() {
    super.initState();
    unawaited(_openCamera());
  }

  @override
  void dispose() {
    final CameraController? controller = _controller;
    _controller = null;
    unawaited(controller?.dispose());
    super.dispose();
  }

  Future<void> _openCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (!mounted) {
        return;
      }
      if (cameras.isEmpty) {
        setState(() {
          _opening = false;
          _error = 'Camera is unavailable. On a phone, allow camera access and reopen Live.';
        });
        return;
      }
      final CameraDescription camera =
          cameras
              .where(
                (CameraDescription item) =>
                    item.lensDirection == CameraLensDirection.back,
              )
              .firstOrNull ??
          cameras.first;
      final CameraController controller = await _startController(camera);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.startImageStream(_onFrame);
      controller.addListener(_onCameraTick);
      setState(() {
        _controller = controller;
        _opening = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _opening = false;
        _error = 'Camera is unavailable. On a phone, allow camera access and reopen Live.';
      });
    }
  }

  Future<CameraController> _startController(CameraDescription camera) async {
    final CameraController preferred = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    try {
      await preferred.initialize();
      return preferred;
    } catch (_) {
      await preferred.dispose();
      final CameraController fallback = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await fallback.initialize();
      return fallback;
    }
  }

  void _onCameraTick() {
    final DeviceOrientation? orientation = _controller?.value.deviceOrientation;
    if (!mounted || orientation == null || orientation == _orientation) {
      return;
    }
    setState(() => _orientation = orientation);
  }

  void _onFrame(CameraImage image) {
    if (_busy || !mounted) {
      return;
    }
    final AsyncValue<ModelSpec> ready = ref.read(detectorReadyProvider);
    if (ready.isLoading || ready.hasError || !ready.hasValue) {
      return;
    }
    final DetectionFrame frame;
    try {
      frame = detectionFrameFromCameraImage(image);
    } catch (_) {
      return;
    }
    _busy = true;
    final double threshold = ref.read(settingsProvider).confidenceThreshold;
    unawaited(_detect(frame, threshold));
  }

  Future<void> _detect(DetectionFrame frame, double threshold) async {
    try {
      final DetectionResult result = await ref
          .read(objectDetectorProvider)
          .detect(frame, confidenceThreshold: threshold);
      if (!mounted) {
        return;
      }
      _noteFps();
      setState(() {
        _detections = result.detections;
        _inference = result.inferenceTime;
      });
    } catch (_) {
      // A single bad buffer should not tear down the preview.
    } finally {
      _busy = false;
    }
  }

  void _noteFps() {
    final DateTime now = DateTime.now();
    _frames.add(now);
    _frames.removeWhere(
      (DateTime stamp) => now.difference(stamp) > const Duration(seconds: 1),
    );
    _fps = _frames.length.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ModelSpec> ready = ref.watch(detectorReadyProvider);
    final DetectionSettings settings = ref.watch(settingsProvider);
    final CameraController? controller = _controller;

    if (_error != null) {
      return _Message(title: 'Live', body: _error!);
    }
    if (_opening || controller == null || !controller.value.isInitialized) {
      return const _Message(title: 'Live', body: 'Opening camera');
    }

    final List<Detection> painted = <Detection>[
      for (final Detection detection in _detections)
        mapDetectionToPreview(
          detection,
          rotationDegrees: _rotation(controller),
          mirrorHorizontally:
              controller.description.lensDirection == CameraLensDirection.front,
        ),
    ];

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: CameraPreview(
          controller,
          child: ready.hasError
              ? _Message(title: 'Model', body: ready.error.toString())
              : DetectionOverlay(
                  detections: ready.isLoading ? const <Detection>[] : painted,
                  inferenceTime: _inference,
                  fps: _fps,
                  modelName: settings.spec.displayName,
                  child: const SizedBox.expand(),
                ),
        ),
      ),
    );
  }

  int _rotation(CameraController controller) {
    return previewRotationDegrees(
      sensorOrientation: controller.description.sensorOrientation,
      orientation: _captureOrientation(controller.value.deviceOrientation),
      frontCamera:
          controller.description.lensDirection == CameraLensDirection.front,
    );
  }

  CaptureOrientation _captureOrientation(DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portraitUp:
        return CaptureOrientation.portraitUp;
      case DeviceOrientation.landscapeLeft:
        return CaptureOrientation.landscapeLeft;
      case DeviceOrientation.portraitDown:
        return CaptureOrientation.portraitDown;
      case DeviceOrientation.landscapeRight:
        return CaptureOrientation.landscapeRight;
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: visionInk,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: visionMuted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
