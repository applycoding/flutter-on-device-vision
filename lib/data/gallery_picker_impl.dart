import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:on_device_vision/domain/gallery_picker.dart';

class ImagePickerGalleryPicker implements GalleryPicker {
  ImagePickerGalleryPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pickImageBytes() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return null;
    }
    return file.readAsBytes();
  }
}
