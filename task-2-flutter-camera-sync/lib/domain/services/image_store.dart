import '../entities/captured_image.dart';
import '../entities/new_upload.dart';

/// Copies photos into app-owned storage so they outlive the camera's cache and
/// the process. The original is left in place; remove it with [delete].
abstract interface class ImageStore {
  Future<NewUpload> persist(CapturedImage image);

  Future<void> delete(String path);
}
