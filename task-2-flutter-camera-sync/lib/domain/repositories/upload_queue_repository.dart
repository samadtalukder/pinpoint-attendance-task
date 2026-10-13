import '../entities/capture_batch.dart';
import '../entities/new_upload.dart';
import '../entities/pending_upload.dart';

/// Persistent upload queue. Rows survive app restarts and upload failures.
abstract interface class UploadQueueRepository {
  /// Persists [items] as one new batch, in the given order.
  Future<CaptureBatch> enqueueBatch(List<NewUpload> items);

  /// Every queued image, oldest first, synced ones included.
  Future<List<PendingUpload>> getAll();

  /// Images still to upload, oldest first.
  Future<List<PendingUpload>> getUnsynced();

  /// True when at least one image is not synced yet. Cheaper than loading the
  /// rows with [getUnsynced].
  Future<bool> hasUnsynced();

  Future<void> markUploading(int id);

  Future<void> markSynced(int id);

  /// Records a failed attempt: attempts + 1, status retrying, row kept.
  Future<void> markFailed(int id, String error);

  /// Resets rows left in `uploading` by a killed process to `waiting`.
  /// Returns how many rows changed.
  Future<int> resetInterrupted();

  /// Removes synced rows (and emptied batches). Returns the removed file paths
  /// so the caller can delete the files.
  Future<List<String>> clearSynced();
}
