enum CameraPermission { granted, denied, permanentlyDenied }

abstract interface class CameraPermissionService {
  Future<CameraPermission> status();

  /// Shows the system prompt. Returns the resulting status.
  Future<CameraPermission> request();

  Future<void> openSettings();
}
