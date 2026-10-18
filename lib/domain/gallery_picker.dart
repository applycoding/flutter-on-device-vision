import 'dart:typed_data';

/// Reads one image from the photo library. Widget tests supply a fake.
abstract interface class GalleryPicker {
  Future<Uint8List?> pickImageBytes();
}
