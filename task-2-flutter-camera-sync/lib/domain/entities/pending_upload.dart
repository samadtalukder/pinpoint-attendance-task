import 'package:equatable/equatable.dart';

import 'upload_status.dart';

/// One image in the upload queue.
class PendingUpload extends Equatable {
  const PendingUpload({
    required this.id,
    required this.batchId,
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
    required this.status,
    required this.attempts,
    required this.createdAt,
    this.lastError,
    this.syncedAt,
  });

  final int id;
  final int batchId;
  final String filePath;
  final String fileName;
  final int sizeBytes;
  final UploadStatus status;
  final int attempts;
  final DateTime createdAt;
  final String? lastError;
  final DateTime? syncedAt;

  @override
  List<Object?> get props => [
    id,
    batchId,
    filePath,
    fileName,
    sizeBytes,
    status,
    attempts,
    createdAt,
    lastError,
    syncedAt,
  ];
}
