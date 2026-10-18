import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_device_vision/app.dart';
import 'package:on_device_vision/data/tflite_object_detector.dart';
import 'package:on_device_vision/providers/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      retry: (int retryCount, Object error) => null,
      overrides: [
        objectDetectorProvider.overrideWith((Ref ref) {
          final TfliteObjectDetector detector = TfliteObjectDetector();
          ref.onDispose(() {
            unawaited(detector.dispose());
          });
          return detector;
        }),
      ],
      child: const VisionApp(),
    ),
  );
}
