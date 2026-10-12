import 'package:sqflite/sqflite.dart';

import '../../core/clock.dart';
import '../../core/constants.dart';
import '../../domain/entities/capture_batch.dart';
import '../../domain/entities/new_upload.dart';
import '../../domain/entities/pending_upload.dart';
import '../../domain/entities/upload_status.dart';
import '../../domain/repositories/upload_queue_repository.dart';

class SqfliteUploadQueueRepository implements UploadQueueRepository {
  SqfliteUploadQueueRepository(this._db, {this._clock = systemClock});

  final Database _db;
  final Clock _clock;

  static const _uploads = DbConstants.uploadsTable;
  static const _batches = DbConstants.batchesTable;

  @override
  Future<CaptureBatch> enqueueBatch(List<NewUpload> items) {
    final now = _clock();
    final nowMs = now.millisecondsSinceEpoch;
    return _db.transaction((txn) async {
      final batchId = await txn.insert(_batches, {'created_at': nowMs});
      for (final item in items) {
        await txn.insert(_uploads, {
          'batch_id': batchId,
          'file_path': item.filePath,
          'file_name': item.fileName,
          'size_bytes': item.sizeBytes,
          'status': UploadStatus.waiting.name,
          'attempts': 0,
          'created_at': nowMs,
        });
      }
      return CaptureBatch(id: batchId, createdAt: now);
    });
  }

  @override
  Future<List<PendingUpload>> getAll() async {
    final rows = await _db.query(_uploads, orderBy: 'created_at ASC, id ASC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<PendingUpload>> getUnsynced() async {
    final rows = await _db.query(
      _uploads,
      where: 'status != ?',
      whereArgs: [UploadStatus.synced.name],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> markUploading(int id) =>
      _update(id, {'status': UploadStatus.uploading.name});

  @override
  Future<void> markSynced(int id) => _update(id, {
    'status': UploadStatus.synced.name,
    'last_error': null,
    'synced_at': _clock().millisecondsSinceEpoch,
  });

  @override
  Future<void> markFailed(int id, String error) async {
    await _db.rawUpdate(
      'UPDATE $_uploads SET status = ?, attempts = attempts + 1, '
      'last_error = ? WHERE id = ?',
      [UploadStatus.retrying.name, error, id],
    );
  }

  @override
  Future<int> resetInterrupted() {
    return _db.update(
      _uploads,
      {'status': UploadStatus.waiting.name},
      where: 'status = ?',
      whereArgs: [UploadStatus.uploading.name],
    );
  }

  @override
  Future<List<String>> clearSynced() {
    return _db.transaction((txn) async {
      final rows = await txn.query(
        _uploads,
        columns: ['file_path'],
        where: 'status = ?',
        whereArgs: [UploadStatus.synced.name],
      );
      await txn.delete(
        _uploads,
        where: 'status = ?',
        whereArgs: [UploadStatus.synced.name],
      );
      await txn.delete(
        _batches,
        where: 'id NOT IN (SELECT DISTINCT batch_id FROM $_uploads)',
      );
      return rows.map((r) => r['file_path']! as String).toList();
    });
  }

  Future<void> _update(int id, Map<String, Object?> values) async {
    await _db.update(_uploads, values, where: 'id = ?', whereArgs: [id]);
  }

  PendingUpload _fromRow(Map<String, Object?> row) {
    final syncedAt = row['synced_at'] as int?;
    return PendingUpload(
      id: row['id']! as int,
      batchId: row['batch_id']! as int,
      filePath: row['file_path']! as String,
      fileName: row['file_name']! as String,
      sizeBytes: row['size_bytes']! as int,
      status: UploadStatus.values.byName(row['status']! as String),
      attempts: row['attempts']! as int,
      lastError: row['last_error'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      syncedAt: syncedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(syncedAt),
    );
  }
}
