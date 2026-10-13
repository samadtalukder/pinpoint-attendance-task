import '../repositories/upload_queue_repository.dart';
import '../services/image_store.dart';

/// Drops uploaded images from the queue and frees their files.
class ClearSyncedUseCase {
  ClearSyncedUseCase(this._queue, this._store);

  final UploadQueueRepository _queue;
  final ImageStore _store;

  Future<void> call() async {
    final paths = await _queue.clearSynced();
    for (final path in paths) {
      await _store.delete(path);
    }
  }
}
