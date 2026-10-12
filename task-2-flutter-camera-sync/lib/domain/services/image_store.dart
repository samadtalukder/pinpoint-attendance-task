import '../entities/captured_image.dart';
import '../entities/new_upload.dart';

/// Moves photos into app-owned storage so they outlive the camera's cache and
/// the process.
abstract interface class ImageStore {
  Future<NewUpload> persist(CapturedImage image);

  Future<void> delete(String path);
}
