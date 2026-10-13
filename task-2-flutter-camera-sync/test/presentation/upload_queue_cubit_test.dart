import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinpoint_capture/core/constants.dart';
import 'package:pinpoint_capture/domain/entities/capture_batch.dart';
import 'package:pinpoint_capture/domain/entities/new_upload.dart';
import 'package:pinpoint_capture/domain/entities/pending_upload.dart';
import 'package:pinpoint_capture/domain/entities/upload_status.dart';
import 'package:pinpoint_capture/domain/repositories/upload_queue_repository.dart';
import 'package:pinpoint_capture/domain/services/connectivity_service.dart';
import 'package:pinpoint_capture/domain/services/image_store.dart';
import 'package:pinpoint_capture/domain/services/mock_upload_mode_store.dart';
import 'package:pinpoint_capture/domain/services/queue_change_bus.dart';
import 'package:pinpoint_capture/domain/services/sync_pause_store.dart';
import 'package:pinpoint_capture/domain/services/sync_scheduler.dart';
import 'package:pinpoint_capture/presentation/upload_manager/upload_queue_cubit.dart';
import 'package:pinpoint_capture/presentation/upload_manager/upload_queue_state.dart';

class MockQueue extends Mock implements UploadQueueRepository {}

class MockConnectivity extends Mock implements ConnectivityService {}

class MockScheduler extends Mock implements SyncScheduler {}

class MockModeStore extends Mock implements MockUploadModeStore {}

class MockPauseStore extends Mock implements SyncPauseStore {}

class MockBus extends Mock implements QueueChangeBus {}

class MockImageStore extends Mock implements ImageStore {}

PendingUpload upload(
  int id,
  UploadStatus status, {
  int size = 100,
  int attempts = 0,
}) => PendingUpload(
  id: id,
  batchId: 1,
  filePath: '/img/$id.jpg',
  fileName: '$id.jpg',
  sizeBytes: size,
  status: status,
  attempts: attempts,
  createdAt: DateTime(2026, 10, 12),
);

void main() {
  late MockQueue queue;
  late MockConnectivity connectivity;
  late MockScheduler scheduler;
  late MockModeStore modeStore;
  late MockPauseStore pauseStore;
  late MockBus bus;
  late MockImageStore imageStore;
  late StreamController<void> changes;
  late StreamController<bool> online;
  var rows = <PendingUpload>[];

  setUpAll(() {
    registerFallbackValue(const <NewUpload>[]);
    registerFallbackValue(MockUploadMode.success);
  });

  setUp(() {
    rows = [];
    queue = MockQueue();
    connectivity = MockConnectivity();
    scheduler = MockScheduler();
    modeStore = MockModeStore();
    pauseStore = MockPauseStore();
    bus = MockBus();
    imageStore = MockImageStore();
    changes = StreamController<void>.broadcast();
    online = StreamController<bool>.broadcast();

    when(() => queue.getAll()).thenAnswer((_) async => rows);
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    when(() => connectivity.onlineChanges).thenAnswer((_) => online.stream);
    when(() => bus.changes).thenAnswer((_) => changes.stream);
    when(() => modeStore.read())
        .thenAnswer((_) async => MockUploadMode.success);
    when(() => modeStore.write(any())).thenAnswer((_) async {});
    when(() => pauseStore.isPaused()).thenAnswer((_) async => false);
    when(() => pauseStore.write(any())).thenAnswer((_) async {});
    when(() => scheduler.requestSync(immediate: any(named: 'immediate')))
        .thenAnswer((_) async {});
    when(() => imageStore.delete(any())).thenAnswer((_) async {});
  });

  Future<UploadQueueCubit> started() async {
    final cubit = UploadQueueCubit(
      queue: queue,
      connectivity: connectivity,
      scheduler: scheduler,
      modeStore: modeStore,
      pauseStore: pauseStore,
      changeBus: bus,
      imageStore: imageStore,
    );
    addTearDown(cubit.close);
    await cubit.initialize();
    return cubit;
  }

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('initialize loads queue, connectivity and mock mode', () async {
    rows = [upload(1, UploadStatus.waiting)];
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    when(() => modeStore.read())
        .thenAnswer((_) async => MockUploadMode.failure);

    final cubit = await started();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.items, rows);
    expect(cubit.state.isOnline, isFalse);
    expect(cubit.state.mode, MockUploadMode.failure);
  });

  test('empty queue is loaded, not left loading', () async {
    final cubit = await started();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.isEmpty, isTrue);
  });

  test('reloads when the worker reports a change', () async {
    final cubit = await started();
    rows = [upload(1, UploadStatus.synced)];

    changes.add(null);
    await pump();

    expect(cubit.state.items, rows);
  });

  test('follows connectivity changes', () async {
    final cubit = await started();

    online.add(false);
    await pump();

    expect(cubit.state.isOnline, isFalse);
  });

  test('progress counts synced images and bytes', () async {
    rows = [
      upload(1, UploadStatus.synced, size: 300),
      upload(2, UploadStatus.retrying, size: 100, attempts: 2),
      upload(3, UploadStatus.waiting, size: 100),
      upload(4, UploadStatus.synced, size: 500),
    ];

    final state = (await started()).state;

    expect(state.total, 4);
    expect(state.syncedCount, 2);
    expect(state.pendingCount, 2);
    expect(state.progress, 0.5);
    expect(state.syncedBytes, 800);
    expect(state.totalBytes, 1000);
    expect(state.pending.map((u) => u.id), [2, 3]);
    expect(state.synced.map((u) => u.id), [4, 1]);
  });

  test('retryNow asks for an immediate sync', () async {
    final cubit = await started();

    await cubit.retryNow();

    verify(() => scheduler.requestSync(immediate: true)).called(1);
    expect(cubit.state.feedback, UploadQueueFeedback.retrying);
  });

  test('setMockMode persists and updates the state', () async {
    final cubit = await started();

    await cubit.setMockMode(MockUploadMode.slow);

    verify(() => modeStore.write(MockUploadMode.slow)).called(1);
    expect(cubit.state.mode, MockUploadMode.slow);
  });

  test('clearSynced deletes files of removed rows and reloads', () async {
    rows = [upload(1, UploadStatus.synced), upload(2, UploadStatus.waiting)];
    when(() => queue.clearSynced()).thenAnswer((_) async {
      rows = [rows.last];
      return ['/img/1.jpg'];
    });
    final cubit = await started();

    await cubit.clearSynced();

    verify(() => imageStore.delete('/img/1.jpg')).called(1);
    expect(cubit.state.items.map((u) => u.id), [2]);
    expect(cubit.state.feedback, UploadQueueFeedback.cleared);
  });

  test('addSampleBatch queues demo images and requests a sync', () async {
    when(
      () => queue.enqueueBatch(any()),
    ).thenAnswer((_) async => CaptureBatch(id: 1, createdAt: DateTime(2026)));
    final cubit = await started();

    await cubit.addSampleBatch();

    final queued =
        verify(() => queue.enqueueBatch(captureAny())).captured.single
            as List<NewUpload>;
    expect(queued.length, SampleConstants.imageCount);
    verify(() => scheduler.requestSync()).called(1);
    expect(cubit.state.feedback, UploadQueueFeedback.sampleAdded);
  });

  test('a failing action reports feedback instead of throwing', () async {
    when(() => scheduler.requestSync(immediate: any(named: 'immediate')))
        .thenThrow(StateError('wm'));
    final cubit = await started();

    await cubit.retryNow();

    expect(cubit.state.feedback, UploadQueueFeedback.actionFailed);
  });

  group('pause all', () {
    test('initialize restores a paused queue', () async {
      when(() => pauseStore.isPaused()).thenAnswer((_) async => true);

      final cubit = await started();

      expect(cubit.state.isPaused, isTrue);
    });

    test('pauseAll persists the flag and updates the state', () async {
      final cubit = await started();

      await cubit.pauseAll();

      verify(() => pauseStore.write(true)).called(1);
      expect(cubit.state.isPaused, isTrue);
      verifyNever(
        () => scheduler.requestSync(immediate: any(named: 'immediate')),
      );
    });

    test('resume clears the flag and restarts the worker now', () async {
      when(() => pauseStore.isPaused()).thenAnswer((_) async => true);
      final cubit = await started();

      await cubit.resume();

      verify(() => pauseStore.write(false)).called(1);
      verify(() => scheduler.requestSync(immediate: true)).called(1);
      expect(cubit.state.isPaused, isFalse);
    });

    test('a failing store reports feedback and keeps the state', () async {
      when(() => pauseStore.write(any())).thenThrow(StateError('prefs'));
      final cubit = await started();

      await cubit.pauseAll();

      expect(cubit.state.isPaused, isFalse);
      expect(cubit.state.feedback, UploadQueueFeedback.actionFailed);
    });
  });
}
