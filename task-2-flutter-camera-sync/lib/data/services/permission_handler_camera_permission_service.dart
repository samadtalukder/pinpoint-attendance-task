import 'package:permission_handler/permission_handler.dart';

import '../../domain/services/camera_permission_service.dart';

class PermissionHandlerCameraPermissionService
    implements CameraPermissionService {
  @override
  Future<CameraPermission> status() async =>
      _map(await Permission.camera.status);

  @override
  Future<CameraPermission> request() async {
    final result = _map(await Permission.camera.request());
    if (result != CameraPermission.denied) return result;
    // Android reports "denied" both after a normal denial and when the system
    // refuses to show the prompt again. Having just asked, no rationale means
    // the prompt can never be shown again, so only settings can fix it.
    final canAskAgain = await Permission.camera.shouldShowRequestRationale;
    return canAskAgain
        ? CameraPermission.denied
        : CameraPermission.permanentlyDenied;
  }

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
