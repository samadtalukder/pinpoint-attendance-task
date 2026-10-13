import '../../core/constants.dart';
import '../entities/new_upload.dart';
import '../repositories/upload_queue_repository.dart';
import '../services/sync_scheduler.dart';

/// Queues a demo batch so the Upload Manager can be shown without photos.
class AddSampleBatchUseCase {
  AddSampleBatchUseCase(this._queue, this._scheduler);

  final UploadQueueRepository _queue;
  final SyncScheduler _scheduler;

  Future<void> call() async {
    await _queue.enqueueBatch([
      for (var i = 1; i <= SampleConstants.imageCount; i++)
        NewUpload(
          filePath:
              '${SampleConstants.pathPrefix}${SampleConstants.namePrefix}$i.jpg',
          fileName: '${SampleConstants.namePrefix}$i.jpg',
          sizeBytes: SampleConstants.imageSizeBytes,
        ),
    ]);
    await _scheduler.requestSync();
  }
}
