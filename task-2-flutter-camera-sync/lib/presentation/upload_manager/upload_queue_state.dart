import 'package:equatable/equatable.dart';

import '../../domain/entities/pending_upload.dart';
import '../../domain/entities/upload_status.dart';
import '../../domain/services/mock_upload_mode_store.dart';

enum UploadQueueFeedback { none, retrying, cleared, sampleAdded, actionFailed }

class UploadQueueState extends Equatable {
  const UploadQueueState({
    this.isLoading = true,
    this.items = const [],
    this.isOnline = true,
    this.mode = MockUploadMode.success,
    this.isPaused = false,
    this.feedback = UploadQueueFeedback.none,
  });

  final bool isLoading;

  /// Queue order, oldest first.
  final List<PendingUpload> items;
  final bool isOnline;
  final MockUploadMode mode;

  /// The user paused syncing; nothing uploads until resumed.
  final bool isPaused;
  final UploadQueueFeedback feedback;

  List<PendingUpload> get pending =>
      items.where((i) => i.status.isPending).toList();

  /// Newest first.
  List<PendingUpload> get synced => items
      .where((i) => i.status == UploadStatus.synced)
      .toList()
      .reversed
      .toList();

  int get total => items.length;
  int get syncedCount => synced.length;
  int get pendingCount => pending.length;
  bool get isEmpty => items.isEmpty;
  bool get hasSynced => syncedCount > 0;
  bool get isUploading => items.any((i) => i.status == UploadStatus.uploading);

  /// 0..1 of images uploaded.
  double get progress => total == 0 ? 0 : syncedCount / total;

  int get totalBytes => items.fold(0, (sum, i) => sum + i.sizeBytes);
  int get syncedBytes => synced.fold(0, (sum, i) => sum + i.sizeBytes);

  UploadQueueState copyWith({
    bool? isLoading,
    List<PendingUpload>? items,
    bool? isOnline,
    MockUploadMode? mode,
    bool? isPaused,
    UploadQueueFeedback? feedback,
  }) {
    return UploadQueueState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      isOnline: isOnline ?? this.isOnline,
      mode: mode ?? this.mode,
      isPaused: isPaused ?? this.isPaused,
      feedback: feedback ?? this.feedback,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    items,
    isOnline,
    mode,
    isPaused,
    feedback,
  ];
}
