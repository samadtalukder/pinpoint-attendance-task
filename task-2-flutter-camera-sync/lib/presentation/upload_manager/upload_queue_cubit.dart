import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants.dart';
import '../../domain/entities/new_upload.dart';
import '../../domain/repositories/upload_queue_repository.dart';
import '../../domain/services/connectivity_service.dart';
import '../../domain/services/image_store.dart';
import '../../domain/services/mock_upload_mode_store.dart';
import '../../domain/services/queue_change_bus.dart';
import '../../domain/services/sync_scheduler.dart';
import 'upload_queue_state.dart';

class UploadQueueCubit extends Cubit<UploadQueueState> {
  UploadQueueCubit({
    required this._queue,
    required this._connectivity,
    required this._scheduler,
    required this._modeStore,
    required this._changeBus,
    required this._imageStore,
  }) : super(const UploadQueueState());

  final UploadQueueRepository _queue;
  final ConnectivityService _connectivity;
  final SyncScheduler _scheduler;
  final MockUploadModeStore _modeStore;
  final QueueChangeBus _changeBus;
  final ImageStore _imageStore;

  StreamSubscription<void>? _changes;
  StreamSubscription<bool>? _online;

  Future<void> initialize() async {
    _changes = _changeBus.changes.listen((_) => _reload());
    _online = _connectivity.onlineChanges.listen((online) {
      if (!isClosed) emit(state.copyWith(isOnline: online));
    });
    final online = await _connectivity.isOnline();
    final mode = await _modeStore.read();
    final items = await _queue.getAll();
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: false,
        items: items,
        isOnline: online,
        mode: mode,
      ),
    );
  }

  Future<void> _reload() async {
    final items = await _queue.getAll();
    if (!isClosed) emit(state.copyWith(isLoading: false, items: items));
  }

  /// Runs the worker now instead of waiting out its backoff.
  Future<void> retryNow() => _run(
    () => _scheduler.requestSync(immediate: true),
    UploadQueueFeedback.retrying,
  );

  Future<void> setMockMode(MockUploadMode mode) async {
    await _modeStore.write(mode);
    if (!isClosed) emit(state.copyWith(mode: mode));
  }

  Future<void> clearSynced() => _run(() async {
    final paths = await _queue.clearSynced();
    for (final path in paths) {
      await _imageStore.delete(path);
    }
    await _reload();
  }, UploadQueueFeedback.cleared);

  Future<void> addSampleBatch() => _run(() async {
    await _queue.enqueueBatch([
      for (var i = 1; i <= SampleConstants.imageCount; i++)
        NewUpload(
          filePath:
              '${SampleConstants.pathPrefix}${SampleConstants.namePrefix}$i.jpg',
          fileName: '${SampleConstants.namePrefix}$i.jpg',
          sizeBytes: SampleConstants.imageSizeBytes,
        ),
    ]);
    await _reload();
    await _scheduler.requestSync();
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
