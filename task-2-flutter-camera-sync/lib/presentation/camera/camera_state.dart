import 'dart:ui';

import 'package:equatable/equatable.dart';

import '../../core/constants.dart';
import '../../domain/entities/captured_image.dart';
import '../../domain/entities/zoom_capabilities.dart';
import '../../domain/services/camera_service.dart';

enum CameraStatus {
  initializing,
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  noCamera,
  error,
}

/// One-shot messages the screen turns into snackbars.
enum CameraFeedback {
  none,
  captureFailed,
  queueFailed,
  batchQueued,
  flipFailed,
}

/// Where the user last tapped to focus. A new [id] restarts the indicator
/// animation even when the position is the same.
class FocusTarget extends Equatable {
  const FocusTarget({required this.position, required this.id});

  /// 0..1 of the preview.
  final Offset position;
  final int id;

  @override
  List<Object?> get props => [position, id];
}

class CameraState extends Equatable {
  const CameraState({
    this.status = CameraStatus.initializing,
    this.capabilities,
    this.lens = CameraLens.back,
    this.flashOn = false,
    this.canFlip = false,
    this.zoom = ZoomConstants.main,
    this.focus,
    this.batch = const [],
    this.isCapturing = false,
    this.isQueueing = false,
    this.feedback = CameraFeedback.none,
    this.lastQueuedCount = 0,
  });

  final CameraStatus status;
  final ZoomCapabilities? capabilities;
  final CameraLens lens;

  /// The user's flash choice. Only applied (and shown) on the back lens.
  final bool flashOn;
  final bool canFlip;
  final double zoom;
  final FocusTarget? focus;

  /// Photos of the batch being captured, not yet queued.
  final List<CapturedImage> batch;
  final bool isCapturing;
  final bool isQueueing;
  final CameraFeedback feedback;

  /// Size of the batch just queued, for the confirmation message.
  final int lastQueuedCount;

  bool get isReady => status == CameraStatus.ready;
  bool get hasFlash => lens == CameraLens.back;
  bool get canCapture => isReady && !isCapturing && !isQueueing;
  bool get canQueue => isReady && batch.isNotEmpty && !isQueueing;

  CameraState copyWith({
    CameraStatus? status,
    ZoomCapabilities? capabilities,
    CameraLens? lens,
    bool? flashOn,
    bool? canFlip,
    double? zoom,
    FocusTarget? focus,
    List<CapturedImage>? batch,
    bool? isCapturing,
    bool? isQueueing,
    CameraFeedback? feedback,
    int? lastQueuedCount,
  }) {
    return CameraState(
      status: status ?? this.status,
      capabilities: capabilities ?? this.capabilities,
      lens: lens ?? this.lens,
      flashOn: flashOn ?? this.flashOn,
      canFlip: canFlip ?? this.canFlip,
      zoom: zoom ?? this.zoom,
      focus: focus ?? this.focus,
      batch: batch ?? this.batch,
      isCapturing: isCapturing ?? this.isCapturing,
      isQueueing: isQueueing ?? this.isQueueing,
      feedback: feedback ?? this.feedback,
      lastQueuedCount: lastQueuedCount ?? this.lastQueuedCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    capabilities,
    lens,
    flashOn,
    canFlip,
    zoom,
    focus,
    batch,
    isCapturing,
    isQueueing,
    feedback,
    lastQueuedCount,
  ];
}
