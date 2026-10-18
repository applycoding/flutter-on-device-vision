import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:on_device_vision/domain/detection_frame.dart';

/// Copies a camera buffer into a [DetectionFrame] before the plugin reuses it.
/// The copy is shallow in cost compared with inference. Color conversion runs
/// later, on the inference isolate.
DetectionFrame detectionFrameFromCameraImage(CameraImage image) {
  final ImageFormatGroup group = image.format.group;
  switch (group) {
    case ImageFormatGroup.yuv420:
      return _yuv420(image);
    case ImageFormatGroup.nv21:
      return _nv21(image);
    case ImageFormatGroup.bgra8888:
      return _bgra(image);
    case ImageFormatGroup.jpeg:
    case ImageFormatGroup.unknown:
      throw UnsupportedError('Camera format $group is not supported.');
  }
}

Yuv420Frame _yuv420(CameraImage image) {
  if (image.planes.length < 3) {
    throw StateError('YUV420 frame did not include three planes.');
  }
  final Plane y = image.planes[0];
  final Plane u = image.planes[1];
  final Plane v = image.planes[2];
  return Yuv420Frame(
    y: Uint8List.fromList(y.bytes),
    u: Uint8List.fromList(u.bytes),
    v: Uint8List.fromList(v.bytes),
    width: image.width,
    height: image.height,
    yRowStride: y.bytesPerRow,
    uvRowStride: u.bytesPerRow,
    uvPixelStride: u.bytesPerPixel ?? 1,
  );
}

Nv21Frame _nv21(CameraImage image) {
  if (image.planes.length < 2) {
    throw StateError('NV21 frame did not include Y and VU planes.');
  }
  final Plane y = image.planes[0];
  final Plane vu = image.planes[1];
  return Nv21Frame(
    y: Uint8List.fromList(y.bytes),
    vu: Uint8List.fromList(vu.bytes),
    width: image.width,
    height: image.height,
    yRowStride: y.bytesPerRow,
    vuRowStride: vu.bytesPerRow,
    vuPixelStride: vu.bytesPerPixel ?? 2,
  );
}

BgraFrame _bgra(CameraImage image) {
  if (image.planes.isEmpty) {
    throw StateError('BGRA frame did not include a plane.');
  }
  final Plane plane = image.planes.first;
  return BgraFrame(
    bytes: Uint8List.fromList(plane.bytes),
    width: image.width,
    height: image.height,
    bytesPerRow: plane.bytesPerRow,
  );
}
