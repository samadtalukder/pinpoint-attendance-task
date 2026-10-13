import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/upload_queue_repository.dart';
import '../../domain/services/connectivity_service.dart';
import '../../domain/services/queue_change_bus.dart';
import '../../domain/services/sync_pause_store.dart';
import '../../domain/services/sync_scheduler.dart';
import '../../domain/usecases/add_sample_batch_use_case.dart';
import '../../domain/usecases/clear_synced_use_case.dart';
import 'upload_queue_state.dart';

class UploadQueueCubit extends Cubit<UploadQueueState> {
  UploadQueueCubit({
    required this._queue,
    required this._connectivity,
    required this._scheduler,
    required this._pauseStore,
    required this._changeBus,
    required this._clearSynced,
    required this._addSampleBatch,
  }) : super(const UploadQueueState());

  final UploadQueueRepository _queue;
  final ConnectivityService _connectivity;
  final SyncScheduler _scheduler;
  final SyncPauseStore _pauseStore;
  final QueueChangeBus _changeBus;
  final ClearSyncedUseCase _clearSynced;
  final AddSampleBatchUseCase _addSampleBatch;

  StreamSubscription<void>? _changes;
  StreamSubscription<bool>? _online;

  Future<void> initialize() async {
    _changes = _changeBus.changes.listen((_) => _reload());
    _online = _connectivity.onlineChanges.listen((online) {
      if (!isClosed) emit(state.copyWith(isOnline: online));
    });
    final online = await _connectivity.isOnline();
    final paused = await _pauseStore.isPaused();
    final items = await _queue.getAll();
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: false,
        items: items,
        isOnline: online,
        isPaused: paused,
      ),
    );
  }

  bool _reloading = false;
  bool _reloadQueued = false;

  /// Worker progress arrives in bursts. Changes that land while a load is
  /// running share one follow-up load instead of one query each.
  Future<void> _reload() async {
    if (_reloading) {
      _reloadQueued = true;
      return;
    }
    _reloading = true;
    try {
      do {
        _reloadQueued = false;
        final items = await _queue.getAll();
        if (!isClosed) emit(state.copyWith(isLoading: false, items: items));
      } while (_reloadQueued && !isClosed);
    } finally {
      _reloading = false;
    }
  }

  /// Runs the worker now instead of waiting out its backoff.
  Future<void> retryNow() => _run(
    () => _scheduler.requestSync(immediate: true),
    UploadQueueFeedback.retrying,
  );

  /// The worker stops after the upload in flight; queued images stay put.
  Future<void> pauseAll() => _run(() async {
    await _pauseStore.write(true);
    if (!isClosed) emit(state.copyWith(isPaused: true));
  }, UploadQueueFeedback.none);

  Future<void> resume() => _run(() async {
    await _pauseStore.write(false);
    if (!isClosed) emit(state.copyWith(isPaused: false));
    await _scheduler.requestSync(immediate: true);
  }, UploadQueueFeedback.none);

  Future<void> clearSynced() => _run(() async {
    await _clearSynced();
    await _reload();
  }, UploadQueueFeedback.cleared);

  Future<void> addSampleBatch() => _run(() async {
    await _addSampleBatch();
    await _reload();
  }, UploadQueueFeedback.sampleAdded);

  void feedbackShown() =>
      emit(state.copyWith(feedback: UploadQueueFeedback.none));

  Future<void> _run(
    Future<void> Function() action,
    UploadQueueFeedback success,
  ) async {
    try {
      await action();
      if (!isClosed) emit(state.copyWith(feedback: success));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(feedback: UploadQueueFeedback.actionFailed));
      }
    }
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    await _online?.cancel();
    return super.close();
  }
}
