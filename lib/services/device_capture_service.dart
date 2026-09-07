import 'package:image_picker/image_picker.dart';

/// Device photo capture boundary. ImagePicker writes camera output to a
/// temporary app-accessible file which is later uploaded by Firebase Storage.
class DeviceCaptureService {
  DeviceCaptureService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  Future<String?> captureHeroImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
      preferredCameraDevice: CameraDevice.rear,
    );
    return image?.path;
  }

  Future<String?> pickHeroImageFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    return image?.path;
  }

  Future<List<String>> pickAdditionalImages() async {
    final images = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    return images.map((image) => image.path).toList(growable: false);
  }
}
