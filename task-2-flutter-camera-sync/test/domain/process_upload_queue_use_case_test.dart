import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint_capture/data/db/app_database.dart';
import 'package:pinpoint_capture/data/repositories/sqflite_upload_queue_repository.dart';
import 'package:pinpoint_capture/domain/entities/new_upload.dart';
import 'package:pinpoint_capture/domain/entities/pending_upload.dart';
import 'package:pinpoint_capture/domain/entities/upload_status.dart';
import 'package:pinpoint_capture/domain/services/queue_change_bus.dart';
import 'package:pinpoint_capture/domain/services/sync_pause_store.dart';
import 'package:pinpoint_capture/domain/services/upload_api.dart';
import 'package:pinpoint_capture/domain/usecases/process_upload_queue_use_case.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeUploadApi implements UploadApi {
  /// File names that fail, with the exception to throw.
  final Map<String, Object> failures = {};

  /// File names that never complete (timeout).
  final Set<String> hangs = {};

  final List<String> uploaded = [];

  /// Runs while an upload is in flight, e.g. to flip the pause flag.
  void Function(String name)? onUpload;

  @override
  Future<void> upload(PendingUpload item) {
    if (hangs.contains(item.fileName)) return Completer<void>().future;
    final failure = failures[item.fileName];
    if (failure != null) return Future.error(failure);
    uploaded.add(item.fileName);
    onUpload?.call(item.fileName);
    return Future.value();
  }
}

class FakePauseStore implements SyncPauseStore {
  bool paused = false;

  @override
  Future<bool> isPaused() async => paused;

  @override
  Future<void> write(bool paused) async => this.paused = paused;
}

class CountingBus implements QueueChangeBus {
  int notifications = 0;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  void notify() => notifications++;
}

void main() {
  sqfliteFfiInit();

  late SqfliteUploadQueueRepository repo;
  late FakeUploadApi api;
  late FakePauseStore pause;
  late ProcessUploadQueueUseCase process;

  setUp(() async {
    final db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    addTearDown(db.close);
    repo = SqfliteUploadQueueRepository(db);
    api = FakeUploadApi();
    pause = FakePauseStore();
    process = ProcessUploadQueueUseCase(
      repo,
      api,
      pauseStore: pause,
      timeout: Duration.zero,
    );
  });

  Future<void> enqueue(List<String> names) => repo.enqueueBatch([
    for (final n in names)
      NewUpload(filePath: '/img/$n', fileName: n, sizeBytes: 10),
  ]);

  test('returns idle when the queue is empty', () async {
    expect(await process(), SyncResult.idle);
  });

  test('uploads everything oldest first and marks it synced', () async {
    await enqueue(['a', 'b', 'c']);

    expect(await process(), SyncResult.completed);

    expect(api.uploaded, ['a', 'b', 'c']);
    expect(await repo.getUnsynced(), isEmpty);
  });

  test(
    'a failing image stays queued as retrying and does not block the rest',
    () async {
      await enqueue(['a', 'b', 'c']);
      api.failures['b'] = const UploadException('No internet connection');

      expect(await process(), SyncResult.failed);

      expect(api.uploaded, ['a', 'c']);
      final left = await repo.getUnsynced();
      expect(left.map((u) => u.fileName), ['b']);
      expect(left.single.status, UploadStatus.retrying);
      expect(left.single.attempts, 1);
      expect(left.single.lastError, 'No internet connection');
    },
  );

  test('stops after the allowed number of failures in a row', () async {
    await enqueue(['a', 'b', 'c', 'd', 'e']);
    for (final n in ['a', 'b', 'c', 'd', 'e']) {
      api.failures[n] = const UploadException('offline');
    }

    expect(await process(), SyncResult.failed);

    final left = await repo.getUnsynced();
    expect(left.map((u) => u.attempts), [1, 1, 1, 0, 0]);
    expect(left[3].status, UploadStatus.waiting);
  });

  test('images queued during a run are uploaded by the same run', () async {
    await enqueue(['a']);
    api.onUpload = (name) {
      if (name == 'a') enqueue(['late']);
    };

    expect(await process(), SyncResult.completed);

    expect(api.uploaded, ['a', 'late']);
    expect(await repo.getUnsynced(), isEmpty);
  });

  test('timeout counts as a slow-connection failure', () async {
    await enqueue(['a']);
    api.hangs.add('a');

    expect(await process(), SyncResult.failed);

    final row = (await repo.getUnsynced()).single;
    expect(row.lastError, ProcessUploadQueueUseCase.slowConnectionMessage);
    expect(row.attempts, 1);
  });

  test('unexpected exception is a failure, never thrown', () async {
    await enqueue(['a']);
    api.failures['a'] = StateError('boom');

    expect(await process(), SyncResult.failed);

    final row = (await repo.getUnsynced()).single;
    expect(row.lastError, ProcessUploadQueueUseCase.unexpectedErrorMessage);
  });

  test('retry after failure uploads the remaining images', () async {
    await enqueue(['a', 'b']);
    api.failures['a'] = const UploadException('offline');
    await process();

    api.failures.clear();
    expect(await process(), SyncResult.completed);

    expect(api.uploaded, ['b', 'a']);
    expect(await repo.getUnsynced(), isEmpty);
    expect((await repo.getAll()).length, 2);
  });

  test('rows stuck in uploading from a killed run are retried', () async {
    await enqueue(['a']);
    await repo.markUploading((await repo.getAll()).single.id);

    expect(await process(), SyncResult.completed);

    expect(api.uploaded, ['a']);
  });

  test('notifies the UI after every row change', () async {
    final bus = CountingBus();
    final observed = ProcessUploadQueueUseCase(
      repo,
      api,
      pauseStore: pause,
      timeout: Duration.zero,
      changeBus: bus,
    );
    await enqueue(['a', 'b']);
    api.failures['b'] = const UploadException('offline');

    await observed();

    // a: uploading + synced, b: uploading + failed.
    expect(bus.notifications, 4);
  });

  group('pause', () {
    test('paused queue uploads nothing and stays queued', () async {
      await enqueue(['a', 'b']);
      pause.paused = true;

      expect(await process(), SyncResult.paused);

      expect(api.uploaded, isEmpty);
      expect((await repo.getUnsynced()).length, 2);
    });

    test('pausing mid-batch stops after the current image', () async {
      await enqueue(['a', 'b', 'c']);
      api.onUpload = (name) {
        if (name == 'a') pause.paused = true;
      };

      expect(await process(), SyncResult.paused);

      expect(api.uploaded, ['a']);
      final left = await repo.getUnsynced();
      expect(left.map((u) => u.fileName), ['b', 'c']);
      expect(left.every((u) => u.status == UploadStatus.waiting), isTrue);
    });

    test('resuming drains the rest', () async {
      await enqueue(['a', 'b']);
      pause.paused = true;
      await process();

      pause.paused = false;
      expect(await process(), SyncResult.completed);

      expect(api.uploaded, ['a', 'b']);
    });
  });
}
