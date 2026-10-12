import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint_capture/data/db/app_database.dart';
import 'package:pinpoint_capture/data/repositories/sqflite_upload_queue_repository.dart';
import 'package:pinpoint_capture/domain/entities/new_upload.dart';
import 'package:pinpoint_capture/domain/entities/upload_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late SqfliteUploadQueueRepository repo;
  var now = DateTime(2026, 10, 12, 9);

  NewUpload item(String name) =>
      NewUpload(filePath: '/img/$name', fileName: name, sizeBytes: 100);

  setUp(() async {
    now = DateTime(2026, 10, 12, 9);
    final db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    repo = SqfliteUploadQueueRepository(db, clock: () => now);
    addTearDown(db.close);
  });

  test('enqueueBatch persists images in order as waiting', () async {
    final batch = await repo.enqueueBatch([item('a.jpg'), item('b.jpg')]);

    final all = await repo.getAll();
    expect(all.map((u) => u.fileName), ['a.jpg', 'b.jpg']);
    expect(all.every((u) => u.batchId == batch.id), isTrue);
    expect(all.every((u) => u.status == UploadStatus.waiting), isTrue);
    expect(all.every((u) => u.attempts == 0), isTrue);
  });

  test('getAll orders batches oldest first', () async {
    await repo.enqueueBatch([item('old.jpg')]);
    now = now.add(const Duration(minutes: 5));
    await repo.enqueueBatch([item('new.jpg')]);

    expect((await repo.getAll()).map((u) => u.fileName), [
      'old.jpg',
      'new.jpg',
    ]);
  });

  test(
    'markFailed keeps the row, counts the attempt and stores the error',
    () async {
      await repo.enqueueBatch([item('a.jpg')]);
      final id = (await repo.getAll()).single.id;

      await repo.markFailed(id, 'no internet');
      await repo.markFailed(id, 'timeout');

      final row = (await repo.getUnsynced()).single;
      expect(row.status, UploadStatus.retrying);
      expect(row.attempts, 2);
      expect(row.lastError, 'timeout');
    },
  );

  test(
    'markSynced removes the row from getUnsynced but keeps it in getAll',
    () async {
      await repo.enqueueBatch([item('a.jpg'), item('b.jpg')]);
      final first = (await repo.getAll()).first;

      await repo.markSynced(first.id);

      expect((await repo.getUnsynced()).map((u) => u.fileName), ['b.jpg']);
      final synced = (await repo.getAll()).first;
      expect(synced.status, UploadStatus.synced);
      expect(synced.syncedAt, now);
      expect(synced.lastError, isNull);
    },
  );

  test('resetInterrupted turns uploading rows back to waiting', () async {
    await repo.enqueueBatch([item('a.jpg'), item('b.jpg')]);
    final all = await repo.getAll();
    await repo.markUploading(all.first.id);

    final changed = await repo.resetInterrupted();

    expect(changed, 1);
    expect((await repo.getAll()).map((u) => u.status), [
      UploadStatus.waiting,
      UploadStatus.waiting,
    ]);
  });

  test(
    'clearSynced removes only synced rows and returns their paths',
    () async {
      await repo.enqueueBatch([item('a.jpg'), item('b.jpg')]);
      final all = await repo.getAll();
      await repo.markSynced(all.first.id);

      final removed = await repo.clearSynced();

      expect(removed, ['/img/a.jpg']);
      expect((await repo.getAll()).map((u) => u.fileName), ['b.jpg']);
    },
  );
}
