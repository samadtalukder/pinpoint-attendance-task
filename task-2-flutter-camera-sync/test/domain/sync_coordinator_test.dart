import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinpoint_capture/domain/repositories/upload_queue_repository.dart';
import 'package:pinpoint_capture/domain/services/connectivity_service.dart';
import 'package:pinpoint_capture/domain/services/sync_scheduler.dart';
import 'package:pinpoint_capture/domain/usecases/sync_coordinator.dart';

class MockQueue extends Mock implements UploadQueueRepository {}

class FakeConnectivity implements ConnectivityService {
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> get onlineChanges => controller.stream;
}

class RecordingScheduler implements SyncScheduler {
  final List<bool> requests = [];

  @override
  Future<void> requestSync({bool immediate = false}) async =>
      requests.add(immediate);
}

void main() {
  late MockQueue queue;
  late FakeConnectivity connectivity;
  late RecordingScheduler scheduler;
  late SyncCoordinator coordinator;
  var hasPending = false;

  setUp(() {
    hasPending = false;
    queue = MockQueue();
    when(() => queue.hasUnsynced()).thenAnswer((_) async => hasPending);
    connectivity = FakeConnectivity();
    scheduler = RecordingScheduler();
    coordinator = SyncCoordinator(queue, connectivity, scheduler);
    addTearDown(coordinator.dispose);
  });

  // Mocked futures resolve in microtasks, so a zero-length timer is enough.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('start schedules a sync when images are queued', () async {
    hasPending = true;
    await coordinator.start();
    expect(scheduler.requests, [false]);
  });

  test('start schedules nothing when the queue is empty', () async {
    await coordinator.start();
    expect(scheduler.requests, isEmpty);
  });

  test(
    'network regained with queued images requests an immediate sync',
    () async {
      hasPending = true;
      await coordinator.start();

      connectivity.controller.add(false);
      await pump();
      expect(scheduler.requests, [false]);

      connectivity.controller.add(true);
      await pump();
      expect(scheduler.requests, [false, true]);
    },
  );

  test('network regained with an empty queue does nothing', () async {
    await coordinator.start();
    connectivity.controller.add(true);
    await pump();
    expect(scheduler.requests, isEmpty);
  });

  test('dispose stops reacting to connectivity', () async {
    hasPending = true;
    await coordinator.start();
    await coordinator.dispose();

    connectivity.controller.add(true);
    await pump();
    expect(scheduler.requests, [false]);
  });

  test('a scheduling failure at start does not throw', () async {
    hasPending = true;
    final failing = SyncCoordinator(queue, connectivity, _ThrowingScheduler());
    addTearDown(failing.dispose);

    await failing.start();
  });
}

class _ThrowingScheduler implements SyncScheduler {
  @override
  Future<void> requestSync({bool immediate = false}) =>
      Future.error(StateError('workmanager'));
}
