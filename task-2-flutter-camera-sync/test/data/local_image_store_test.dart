import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pinpoint_capture/core/constants.dart';
import 'package:pinpoint_capture/data/files/local_image_store.dart';
import 'package:pinpoint_capture/domain/entities/captured_image.dart';

void main() {
  late Directory root;
  late Directory cache;
  late LocalImageStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('store_root');
    cache = await Directory.systemTemp.createTemp('store_cache');
    store = LocalImageStore(
      () async => root,
      clock: () => DateTime.fromMicrosecondsSinceEpoch(42),
    );
    addTearDown(() async {
      await root.delete(recursive: true);
      await cache.delete(recursive: true);
    });
  });

  Future<CapturedImage> photo(String name) async {
    final file = File(p.join(cache.path, name));
    await file.writeAsBytes([1, 2, 3, 4]);
    return CapturedImage(path: file.path, name: name, sizeBytes: 4);
  }

  test('persist moves the file into app storage', () async {
    final image = await photo('a.jpg');

    final stored = await store.persist(image);

    expect(stored.fileName, '42_a.jpg');
    expect(stored.sizeBytes, 4);
    expect(
      p.dirname(stored.filePath),
      p.join(root.path, StorageConstants.capturesDirectory),
    );
    expect(File(stored.filePath).existsSync(), isTrue);
    expect(File(image.path).existsSync(), isFalse);
  });

  test('delete removes the file and tolerates a missing one', () async {
    final stored = await store.persist(await photo('a.jpg'));

    await store.delete(stored.filePath);
    await store.delete(stored.filePath);

    expect(File(stored.filePath).existsSync(), isFalse);
  });
}
