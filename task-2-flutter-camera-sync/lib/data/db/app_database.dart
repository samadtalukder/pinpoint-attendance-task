import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';

/// Opens the local database and owns its schema.
abstract final class AppDatabase {
  /// [path] defaults to the app databases directory; tests pass
  /// `inMemoryDatabasePath`. [factory] defaults to the platform factory.
  static Future<Database> open({String? path, DatabaseFactory? factory}) async {
    final dbFactory = factory ?? databaseFactory;
    final resolved =
        path ??
        p.join(await dbFactory.getDatabasesPath(), DbConstants.fileName);
    return dbFactory.openDatabase(
      resolved,
      options: OpenDatabaseOptions(
        version: DbConstants.version,
        onCreate: _onCreate,
      ),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.batchesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE ${DbConstants.uploadsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        synced_at INTEGER
      )''');
  }
}
