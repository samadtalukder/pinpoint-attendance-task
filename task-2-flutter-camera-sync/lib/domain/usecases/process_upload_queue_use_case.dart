import 'dart:async';

import '../../core/constants.dart';
import '../repositories/upload_queue_repository.dart';
import '../services/queue_change_bus.dart';
import '../services/upload_api.dart';

enum SyncResult {
  /// Nothing was queued.
  idle,

  /// Every queued image was uploaded.
  completed,

  /// An upload failed; remaining images stay queued for a retry.
  failed,
}

/// Uploads the queue oldest first. Stops at the first failure so a dead
/// connection is not hammered; failed and untouched rows stay queued.
class ProcessUploadQueueUseCase {
  ProcessUploadQueueUseCase(
    this._queue,
    this._api, {
    this._timeout = SyncConstants.uploadTimeout,
    this._changeBus,
  });

  final UploadQueueRepository _queue;
  final UploadApi _api;
  final Duration _timeout;

  /// Told after every row change so an open Upload Manager shows live
  /// progress.
  final QueueChangeBus? _changeBus;

  static const String slowConnectionMessage = 'Connection too slow';
  static const String unexpectedErrorMessage = 'Unexpected upload error';

  Future<SyncResult> call() async {
    // A killed process can leave rows in `uploading`. The worker is the only
    // uploader, so anything still `uploading` here is stale.
    if (await _queue.resetInterrupted() > 0) _changeBus?.notify();

    final pending = await _queue.getUnsynced();
    if (pending.isEmpty) return SyncResult.idle;

    for (final item in pending) {
      await _queue.markUploading(item.id);
      _changeBus?.notify();
      try {
        await _api.upload(item).timeout(_timeout);
        await _queue.markSynced(item.id);
        _changeBus?.notify();
      } on TimeoutException {
        await _queue.markFailed(item.id, slowConnectionMessage);
        _changeBus?.notify();
        return SyncResult.failed;
      } on UploadException catch (e) {
        await _queue.markFailed(item.id, e.message);
        _changeBus?.notify();
        return SyncResult.failed;
      } catch (_) {
        // Never let an unexpected error crash the worker; keep the row queued.
        await _queue.markFailed(item.id, unexpectedErrorMessage);
        _changeBus?.notify();
        return SyncResult.failed;
      }
    }
    return SyncResult.completed;
  }
}
