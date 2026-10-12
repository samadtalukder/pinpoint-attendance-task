import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/clock.dart';
import '../../core/constants.dart';
import '../../domain/entities/captured_image.dart';
import '../../domain/entities/new_upload.dart';
import '../../domain/services/image_store.dart';

class LocalImageStore implements ImageStore {
  /// [rootProvider] returns the app documents directory.
  LocalImageStore(this._rootProvider, {this._clock = systemClock});

  final Future<Directory> Function() _rootProvider;
  final Clock _clock;

  @override
  Future<NewUpload> persist(CapturedImage image) async {
    final root = await _rootProvider();
    final dir = Directory(
      p.join(root.path, StorageConstants.capturesDirectory),
    );
    await dir.create(recursive: true);

    final fileName = '${_clock().microsecondsSinceEpoch}_${image.name}';
    final target = File(p.join(dir.path, fileName));
    final source = File(image.path);
    // Copy then delete: rename fails across volumes (cache vs documents).
    await source.copy(target.path);
    await _deleteQuietly(source);

    return NewUpload(
      filePath: target.path,
      fileName: fileName,
      sizeBytes: await target.length(),
    );
  }

  @override
  Future<void> delete(String path) => _deleteQuietly(File(path));

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Already gone or locked; a leftover file is harmless.
    }
  }
}
