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

  Future<void> initialize() async {
    _released = false;
    emit(state.copyWith(status: CameraStatus.initializing));

    var permission = await _permission.status();
    if (permission == CameraPermission.denied) {
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
    try {
      final capabilities = await _camera.initialize();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CameraStatus.ready,
          capabilities: capabilities,
          zoom: capabilities.clamp(ZoomConstants.main),
        ),
      );
    } on CameraFailure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: failure.type == CameraFailureType.noCamera
              ? CameraStatus.noCamera
              : CameraStatus.error,
        ),
      );
    }
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
    } on CameraFailure {
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
    if (!state.isReady) return;
    _released = true;
    emit(state.copyWith(status: CameraStatus.initializing));
    await _camera.dispose();
  }

  /// Restarts a released camera, and re-checks after a failure, e.g. the
  /// user granted the permission in system settings.
  Future<void> onAppResumed() async {
    final retryable =
        _released ||
        switch (state.status) {
          CameraStatus.permissionDenied ||
          CameraStatus.permissionPermanentlyDenied ||
          CameraStatus.error => true,
          _ => false,
        };
    if (retryable) await initialize();
  }

  Future<void> openSettings() => _permission.openSettings();

  @override
  Future<void> close() async {
    await _camera.dispose();
    return super.close();
  }
}
