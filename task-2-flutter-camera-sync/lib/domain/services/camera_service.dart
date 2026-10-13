import '../entities/captured_image.dart';
import '../entities/zoom_capabilities.dart';

enum CameraFailureType {
  /// The device has no back camera.
  noCamera,

  /// The camera exists but could not start, or failed while in use.
  unavailable,
}

class CameraFailure implements Exception {
  const CameraFailure(this.type, [this.message]);

  final CameraFailureType type;
  final String? message;

  @override
  String toString() =>
      'CameraFailure($type${message == null ? '' : ': $message'})';
}

enum CameraLens { back, front }

/// Camera control. Throws [CameraFailure] when it cannot start or
/// capture; focus and zoom problems are not fatal and are swallowed.
abstract interface class CameraService {
  /// Whether the device has both a back and a front camera. Valid after
  /// [initialize].
  bool get canFlip;

  /// Starts the [lens] camera and reports its zoom range. Safe to call again
  /// after [dispose].
  Future<ZoomCapabilities> initialize({CameraLens lens = CameraLens.back});

  /// Turns the capture flash on (fires with every photo) or off. Lenses
  /// without a flash ignore it.
  Future<void> setFlash(bool on);

  /// Zooms to [zoom]. Values below 1 select the ultrawide lens when the
  /// device has one.
  Future<void> setZoom(double zoom);

  /// Focuses and meters on a point given in 0..1 of the preview.
  Future<void> focusAt(double x, double y);

  Future<CapturedImage> capture();

  /// Releases the camera.
  Future<void> dispose();
}
