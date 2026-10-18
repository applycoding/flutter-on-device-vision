import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:on_device_vision/app.dart';
import 'package:on_device_vision/data/fake_object_detector.dart';
import 'package:on_device_vision/data/image_decoding.dart';
import 'package:on_device_vision/domain/detection.dart';
import 'package:on_device_vision/domain/gallery_picker.dart';
import 'package:on_device_vision/providers/providers.dart';
import 'package:on_device_vision/ui/detection_overlay.dart';
import 'package:on_device_vision/ui/gallery_page.dart';
import 'package:on_device_vision/ui/settings_page.dart';

void main() {
  testWidgets('overlay draws labels, inference time, and fps', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: DetectionOverlay(
              detections: <Detection>[
                Detection(
                  label: 'person',
                  classId: 0,
                  confidence: 0.91,
                  left: 0.1,
                  top: 0.2,
                  right: 0.5,
                  bottom: 0.8,
                ),
              ],
              inferenceTime: Duration(milliseconds: 18),
              fps: 24,
              modelName: 'SSD MobileNet V1',
              child: ColoredBox(color: Color(0xFF000000)),
            ),
          ),
        ),
      ),
    );

    expect(find.text('person 91%'), findsOneWidget);
    expect(find.textContaining('18 ms'), findsOneWidget);
    expect(find.textContaining('24 fps'), findsOneWidget);
    expect(find.textContaining('SSD MobileNet V1'), findsOneWidget);
  });

  testWidgets('settings screen updates the threshold and model', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer(
      retry: (int retryCount, Object error) => null,
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    expect(find.textContaining('Confidence'), findsOneWidget);
    await tester.tap(find.byKey(const Key('model-efficientDetLite0')));
    await tester.pump();
    expect(
      container.read(settingsProvider).spec.displayName,
      'EfficientDet-Lite0',
    );

    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(0.42);
    await tester.pump();
    expect(
      container.read(settingsProvider).confidenceThreshold,
      closeTo(0.42, 0.001),
    );
    expect(find.textContaining('42%'), findsOneWidget);
  });

  testWidgets('gallery mode shows fake detections for a picked photo', (
    WidgetTester tester,
  ) async {
    final img.Image picture = img.Image(width: 4, height: 4);
    img.fill(picture, color: img.ColorRgb8(12, 24, 36));
    final Uint8List png = Uint8List.fromList(img.encodePng(picture));
    final FakeObjectDetector detector = FakeObjectDetector(
      detections: const <Detection>[
        Detection(
          label: 'cup',
          classId: 41,
          confidence: 0.88,
          left: 0.2,
          top: 0.2,
          right: 0.6,
          bottom: 0.7,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        retry: (int retryCount, Object error) => null,
        overrides: [
          objectDetectorProvider.overrideWith((Ref ref) => detector),
          galleryPickerProvider.overrideWith((Ref ref) => _BytesPicker(png)),
          imageDecoderProvider.overrideWith(
            (Ref ref) => const SyncImageDecoder(),
          ),
        ],
        child: const MaterialApp(home: GalleryPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('choose-photo')));
    await tester.pumpAndSettle();

    expect(find.textContaining('cup'), findsOneWidget);
    expect(find.textContaining('12 ms'), findsOneWidget);
    expect(detector.detectCount, 1);
    expect(detector.loadedSpec?.displayName, 'SSD MobileNet V1');
  });

  testWidgets(
    'live, gallery, and settings navigation stays available without a camera',
    (WidgetTester tester) async {
      const MethodChannel cameraChannel = MethodChannel(
        'plugins.flutter.io/camera',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        cameraChannel,
        (MethodCall call) async {
          if (call.method == 'availableCameras') {
            return <Map<String, Object?>>[];
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          cameraChannel,
          null,
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          retry: (int retryCount, Object error) => null,
          overrides: [
            objectDetectorProvider.overrideWith(
              (Ref ref) => FakeObjectDetector(),
            ),
            imageDecoderProvider.overrideWith(
              (Ref ref) => const SyncImageDecoder(),
            ),
          ],
          child: const VisionApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Camera is unavailable'), findsOneWidget);

      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a photo'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('SSD MobileNet V1'), findsOneWidget);
      expect(
        find.textContaining('Portfolio demo for Arpan Bom'),
        findsOneWidget,
      );
    },
  );
}

class _BytesPicker implements GalleryPicker {
  _BytesPicker(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List?> pickImageBytes() async => bytes;
}
