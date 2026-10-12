import 'package:permission_handler/permission_handler.dart';

import '../../domain/services/camera_permission_service.dart';

class PermissionHandlerCameraPermissionService
    implements CameraPermissionService {
  @override
  Future<CameraPermission> status() async =>
      _map(await Permission.camera.status);

  @override
  Future<CameraPermission> request() async =>
      _map(await Permission.camera.request());

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  static CameraPermission _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return CameraPermission.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraPermission.permanentlyDenied;
    }
    return CameraPermission.denied;
  }
}
