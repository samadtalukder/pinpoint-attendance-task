import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants.dart';
import '../../domain/services/camera_permission_service.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/usecases/enqueue_batch_use_case.dart';
import 'camera_state.dart';

class CameraCubit extends Cubit<CameraState> {
  CameraCubit(this._camera, this._permission, this._enqueueBatch)
    : super(const CameraState());

  final CameraService _camera;
  final CameraPermissionService _permission;
  final EnqueueBatchUseCase _enqueueBatch;

  double _pinchBase = ZoomConstants.main;
  bool _zoomInFlight = false;
  double? _pendingZoom;
  int _focusCounter = 0;
  bool _released = false;

  /// [promptForPermission] is false for the first open and for lifecycle
  /// restarts. On first open the screen explains why the camera is needed and
  /// its button asks. On resume, the system dialog itself pauses and resumes
  /// the app, so prompting there would loop.
  Future<void> initialize({bool promptForPermission = true}) async {
    _released = false;
    emit(state.copyWith(status: CameraStatus.initializing));

    var permission = await _permission.status();
    if (promptForPermission && permission == CameraPermission.denied) {
      permission = await _permission.request();
    }
    if (isClosed) return;
    switch (permission) {
      case CameraPermission.denied:
        emit(state.copyWith(status: CameraStatus.permissionDenied));
      case CameraPermission.permanentlyDenied:
        emit(state.copyWith(status: CameraStatus.permissionPermanentlyDenied));
      case CameraPermission.granted:
        await _startCamera();
    }
  }

  Future<void> _startCamera() async {
    final failure = await _open();
    if (failure == null || isClosed) return;
    emit(
      state.copyWith(
        status: failure.type == CameraFailureType.noCamera
            ? CameraStatus.noCamera
            : CameraStatus.error,
      ),
    );
  }

  /// Starts the camera on the current lens. Emits `ready` and returns null on
  /// success; returns the failure without emitting otherwise.
  Future<CameraFailure?> _open() async {
    try {
      final capabilities = await _camera.initialize(lens: state.lens);
      if (_released && !isClosed) {
        // The app went to the background while the camera was starting. Give
        // it back; onAppResumed restarts it.
        await _camera.dispose();
        return null;
      }
      if (state.flashOn && state.hasFlash) await _camera.setFlash(true);
      if (isClosed) return null;
      emit(
        state.copyWith(
          status: CameraStatus.ready,
          capabilities: capabilities,
          canFlip: _camera.canFlip,
          zoom: capabilities.clamp(ZoomConstants.main),
        ),
      );
      return null;
    } on CameraFailure catch (failure) {
      return failure;
    } catch (_) {
      return const CameraFailure(CameraFailureType.unavailable);
    }
  }

  Future<void> toggleFlash() async {
    if (!state.isReady || !state.hasFlash) return;
    final on = !state.flashOn;
    emit(state.copyWith(flashOn: on));
    await _camera.setFlash(on);
  }

  /// Switches between back and front camera. The preview widget leaves the
  /// tree first (status `initializing`), like on pause. If the other lens
  /// cannot start, the previous one comes back.
  Future<void> flipCamera() async {
    if (!state.isReady || !state.canFlip) return;
    final previous = state.lens;
    final next = previous == CameraLens.back
        ? CameraLens.front
        : CameraLens.back;
    emit(state.copyWith(status: CameraStatus.initializing, lens: next));
    final failure = await _open();
    if (failure == null || isClosed) return;
    emit(state.copyWith(lens: previous));
    final fallback = await _open();
    if (isClosed) return;
    emit(
      state.copyWith(
        status: fallback == null ? CameraStatus.ready : CameraStatus.error,
        feedback: CameraFeedback.flipFailed,
      ),
    );
  }

  /// Slider and preset buttons.
  Future<void> setZoom(double zoom) async {
    final capabilities = state.capabilities;
    if (!state.isReady || capabilities == null) return;
    final clamped = capabilities.clamp(zoom);
    emit(state.copyWith(zoom: clamped));
    await _applyZoom(clamped);
  }

  void pinchStarted() => _pinchBase = state.zoom;

  /// [scale] is the pinch scale relative to where the gesture started.
  Future<void> pinchUpdated(double scale) => setZoom(_pinchBase * scale);

  /// Latest value wins: while the camera is busy with one zoom, newer values
  /// replace each other instead of queueing.
  Future<void> _applyZoom(double zoom) async {
    if (_zoomInFlight) {
      _pendingZoom = zoom;
      return;
    }
    _zoomInFlight = true;
    try {
      var next = zoom;
      while (true) {
        await _camera.setZoom(next);
        final pending = _pendingZoom;
        if (pending == null || pending == next) break;
        _pendingZoom = null;
        next = pending;
      }
    } finally {
      _pendingZoom = null;
      _zoomInFlight = false;
    }
  }

  /// [normalized] is the tap position as 0..1 of the preview.
  Future<void> focusAt(Offset normalized) async {
    if (!state.isReady) return;
    emit(
      state.copyWith(
        focus: FocusTarget(position: normalized, id: ++_focusCounter),
      ),
    );
    await _camera.focusAt(normalized.dx, normalized.dy);
  }

  Future<void> capture() async {
    if (!state.canCapture) return;
    emit(state.copyWith(isCapturing: true));
    try {
      final image = await _camera.capture();
      if (isClosed) return;
      emit(state.copyWith(batch: [...state.batch, image], isCapturing: false));
    } catch (_) {
      // Any failure (camera, file system) must release the shutter.
      if (isClosed) return;
      emit(
        state.copyWith(
          isCapturing: false,
          feedback: CameraFeedback.captureFailed,
        ),
      );
    }
  }

  Future<void> queueBatch() async {
    if (!state.canQueue) return;
    final images = state.batch;
    emit(state.copyWith(isQueueing: true));
    try {
      await _enqueueBatch(images);
      if (isClosed) return;
      emit(
        state.copyWith(
          batch: const [],
          isQueueing: false,
          feedback: CameraFeedback.batchQueued,
          lastQueuedCount: images.length,
        ),
      );
    } catch (_) {
      // The photos stay in the batch so the user can try again.
      if (isClosed) return;
      emit(
        state.copyWith(isQueueing: false, feedback: CameraFeedback.queueFailed),
      );
    }
  }

  void feedbackShown() => emit(state.copyWith(feedback: CameraFeedback.none));

  /// The camera must be released while the app is in the background. The
  /// state leaves `ready` first so the preview widget is gone before the
  /// controller is disposed.
  Future<void> onAppPaused() async {
    // Also remembered while the camera is still starting; see [_open].
    _released = true;
    if (!state.isReady) return;
    emit(state.copyWith(status: CameraStatus.initializing));
    await _camera.dispose();
  }

  /// Restarts a released camera, and re-checks after a failure, e.g. the
  /// user granted the permission in system settings.
  Future<void> onAppResumed() async {
    switch (state.status) {
      case CameraStatus.permissionDenied:
      case CameraStatus.permissionPermanentlyDenied:
        // status() cannot tell "denied" from "blocked" on Android, so it may
        // only upgrade to granted, never overwrite what request() reported.
        if (await _permission.status() == CameraPermission.granted) {
          await initialize(promptForPermission: false);
        }
      case CameraStatus.error:
        await initialize(promptForPermission: false);
      default:
        if (_released) await initialize(promptForPermission: false);
    }
  }

  Future<void> openSettings() => _permission.openSettings();

  @override
  Future<void> close() async {
    await _camera.dispose();
    return super.close();
  }
}
