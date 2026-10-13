import 'dart:async';

import '../../core/constants.dart';
import '../entities/pending_upload.dart';
import '../repositories/upload_queue_repository.dart';
import '../services/queue_change_bus.dart';
import '../services/sync_pause_store.dart';
import '../services/upload_api.dart';

enum SyncResult {
  /// Nothing was queued.
  idle,

  /// Every queued image was uploaded.
  completed,

  /// An upload failed; failed and unattempted images stay queued for a retry.
  failed,

  /// The user paused syncing; remaining images stay queued untouched.
  paused,
}

/// Uploads the queue oldest first. One failing image does not block the ones
/// behind it; the run stops after [SyncConstants.maxConsecutiveFailures]
/// failures in a row so a dead connection is not hammered. Failed and
/// untouched rows stay queued. Images queued while the run is in progress are
/// picked up by the same run. Checks the pause flag before every image, so
/// pausing takes effect after the upload in flight.
class ProcessUploadQueueUseCase {
  ProcessUploadQueueUseCase(
    this._queue,
    this._api, {
    required this._pauseStore,
    this._timeout = SyncConstants.uploadTimeout,
    this._changeBus,
  });

  final UploadQueueRepository _queue;
  final UploadApi _api;
  final SyncPauseStore _pauseStore;
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

    // Rows tried in this run are not retried until the next run.
    final attempted = <int>{};
    var failedInARow = 0;
    var anyFailed = false;

    while (true) {
      // Re-read the queue so batches added mid-run are not left waiting for a
      // sync request that a running job would ignore.
      final pending = (await _queue.getUnsynced())
          .where((item) => !attempted.contains(item.id))
          .toList();
      if (pending.isEmpty) break;

      for (final item in pending) {
        if (await _pauseStore.isPaused()) return SyncResult.paused;
        attempted.add(item.id);
        await _queue.markUploading(item.id);
        _changeBus?.notify();

        final error = await _upload(item);
        if (error == null) {
          await _queue.markSynced(item.id);
          failedInARow = 0;
        } else {
          await _queue.markFailed(item.id, error);
          anyFailed = true;
          if (++failedInARow >= SyncConstants.maxConsecutiveFailures) {
            _changeBus?.notify();
            return SyncResult.failed;
          }
        }
        _changeBus?.notify();
      }
    }

    if (attempted.isEmpty) return SyncResult.idle;
    return anyFailed ? SyncResult.failed : SyncResult.completed;
  }

  /// Returns null on success, otherwise the message to store on the row.
  /// Never throws, so an unexpected error cannot crash the worker.
  Future<String?> _upload(PendingUpload item) async {
    try {
      await _api.upload(item).timeout(_timeout);
      return null;
    } on TimeoutException {
      return slowConnectionMessage;
    } on UploadException catch (e) {
      return e.message;
    } catch (_) {
      return unexpectedErrorMessage;
    }
  }
}
