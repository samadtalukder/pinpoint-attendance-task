import '../entities/pending_upload.dart';

/// Sends one image to the backend. Completes on success, throws
/// [UploadException] on failure.
abstract interface class UploadApi {
  Future<void> upload(PendingUpload item);
}

class UploadException implements Exception {
  const UploadException(this.message);

  final String message;

  @override
  String toString() => 'UploadException: $message';
}
