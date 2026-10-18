import 'package:on_device_vision/domain/detection.dart';

/// How the device is being held, independent of Flutter's services library
/// so the mapping can be unit tested on its own.
enum CaptureOrientation {
  portraitUp,
  landscapeLeft,
  portraitDown,
  landscapeRight,
}

/// Degrees clockwise to rotate a sensor-buffer box into the upright preview.
///
/// Back cameras use `sensorOrientation - device`. Front cameras use the sum.
/// This matches the compensation used by the camera plugin's image stream,
/// which is delivered in sensor orientation while the preview is upright.
int previewRotationDegrees({
  required int sensorOrientation,
  required CaptureOrientation orientation,
  required bool frontCamera,
}) {
  final int deviceDegrees = switch (orientation) {
    CaptureOrientation.portraitUp => 0,
    CaptureOrientation.landscapeLeft => 90,
    CaptureOrientation.portraitDown => 180,
    CaptureOrientation.landscapeRight => 270,
  };
  if (frontCamera) {
    return (sensorOrientation + deviceDegrees) % 360;
  }
  return (sensorOrientation - deviceDegrees + 360) % 360;
}

/// Maps a normalized sensor-space box into preview space.
Detection mapDetectionToPreview(
  Detection detection, {
  required int rotationDegrees,
  required bool mirrorHorizontally,
}) {
  final double left = detection.left;
  final double top = detection.top;
  final double right = detection.right;
  final double bottom = detection.bottom;
  final (
    double nextLeft,
    double nextTop,
    double nextRight,
    double nextBottom,
  ) = switch (rotationDegrees % 360) {
    0 => (left, top, right, bottom),
    90 => (1 - bottom, left, 1 - top, right),
    180 => (1 - right, 1 - bottom, 1 - left, 1 - top),
    270 => (top, 1 - right, bottom, 1 - left),
    _ => throw ArgumentError(
      'Rotation must be a multiple of 90 degrees, got $rotationDegrees.',
    ),
  };
  if (!mirrorHorizontally) {
    return detection.copyWithBox(
      left: nextLeft,
      top: nextTop,
      right: nextRight,
      bottom: nextBottom,
    );
  }
  return detection.copyWithBox(
    left: 1 - nextRight,
    top: nextTop,
    right: 1 - nextLeft,
    bottom: nextBottom,
  );
}
