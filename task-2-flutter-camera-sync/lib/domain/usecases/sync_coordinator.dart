import 'dart:async';

import '../repositories/upload_queue_repository.dart';
import '../services/connectivity_service.dart';
import '../services/sync_scheduler.dart';

/// Foreground side of the sync engine: makes sure a worker is scheduled when
/// the app starts with queued images and when the network comes back.
/// Uploading itself is done only by the worker.
class SyncCoordinator {
  SyncCoordinator(this._queue, this._connectivity, this._scheduler);

  final UploadQueueRepository _queue;
  final ConnectivityService _connectivity;
  final SyncScheduler _scheduler;

  StreamSubscription<bool>? _subscription;

  Future<void> start() async {
    if (_subscription != null) return;
    _subscription = _connectivity.onlineChanges.listen(_onOnlineChanged);
    if (await _queue.hasUnsynced()) await _requestSync();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onOnlineChanged(bool online) async {
    if (online && await _queue.hasUnsynced()) {
      await _requestSync(immediate: true);
    }
  }

  /// A scheduling failure must not break app start or surface as an
  /// unhandled error; the next start or network change tries again.
  Future<void> _requestSync({bool immediate = false}) async {
    try {
      await _scheduler.requestSync(immediate: immediate);
    } catch (_) {}
  }
}
