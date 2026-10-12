import 'dart:ui';

import 'package:equatable/equatable.dart';

import '../../core/constants.dart';
import '../../domain/entities/captured_image.dart';
import '../../domain/entities/zoom_capabilities.dart';

enum CameraStatus {
  initializing,
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  noCamera,
  error,
}

/// One-shot messages the screen turns into snackbars.
enum CameraFeedback { none, captureFailed, queueFailed, batchQueued }

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
  bool get canCapture => isReady && !isCapturing && !isQueueing;
  bool get canQueue => isReady && batch.isNotEmpty && !isQueueing;

  CameraState copyWith({
    CameraStatus? status,
    ZoomCapabilities? capabilities,
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
    zoom,
    focus,
    batch,
    isCapturing,
    isQueueing,
    feedback,
    lastQueuedCount,
  ];
}
