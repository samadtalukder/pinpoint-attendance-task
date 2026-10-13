import '../entities/capture_batch.dart';
import '../entities/captured_image.dart';
import '../entities/new_upload.dart';
import '../repositories/upload_queue_repository.dart';
import '../services/image_store.dart';
import '../services/sync_scheduler.dart';

/// Turns captured photos into a queued batch and asks for a sync.
class EnqueueBatchUseCase {
  EnqueueBatchUseCase(this._store, this._queue, this._scheduler);

  final ImageStore _store;
  final UploadQueueRepository _queue;
  final SyncScheduler _scheduler;

  Future<CaptureBatch> call(List<CapturedImage> images) async {
    if (images.isEmpty) throw ArgumentError('A batch needs at least one image');

    final stored = <NewUpload>[];
    final CaptureBatch batch;
    try {
      for (final image in images) {
        stored.add(await _store.persist(image));
      }
      batch = await _queue.enqueueBatch(stored);
    } catch (_) {
      // Do not leave orphaned copies. The source photos are untouched, so the
      // caller keeps them and can retry.
      for (final item in stored) {
        await _store.delete(item.filePath);
      }
      rethrow;
    }

    // Only now that the batch is committed are the originals redundant.
    for (final image in images) {
      await _store.delete(image.path);
    }

    try {
      await _scheduler.requestSync();
    } catch (_) {
      // The batch is safely queued. SyncCoordinator schedules a sync on the
      // next start or when the network returns.
    }
    return batch;
  }
}
