import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinpoint_capture/domain/entities/capture_batch.dart';
import 'package:pinpoint_capture/domain/entities/captured_image.dart';
import 'package:pinpoint_capture/domain/entities/new_upload.dart';
import 'package:pinpoint_capture/domain/repositories/upload_queue_repository.dart';
import 'package:pinpoint_capture/domain/services/image_store.dart';
import 'package:pinpoint_capture/domain/services/sync_scheduler.dart';
import 'package:pinpoint_capture/domain/usecases/enqueue_batch_use_case.dart';

class MockStore extends Mock implements ImageStore {}

class MockQueue extends Mock implements UploadQueueRepository {}

class MockScheduler extends Mock implements SyncScheduler {}

void main() {
  late MockStore store;
  late MockQueue queue;
  late MockScheduler scheduler;
  late EnqueueBatchUseCase enqueue;

  const images = [
    CapturedImage(path: '/cache/a.jpg', name: 'a.jpg', sizeBytes: 1),
    CapturedImage(path: '/cache/b.jpg', name: 'b.jpg', sizeBytes: 2),
  ];
  final batch = CaptureBatch(id: 7, createdAt: DateTime(2026, 10, 12));

  setUpAll(() {
    registerFallbackValue(const <NewUpload>[]);
    registerFallbackValue(images.first);
  });

  setUp(() {
    store = MockStore();
    queue = MockQueue();
    scheduler = MockScheduler();
    enqueue = EnqueueBatchUseCase(store, queue, scheduler);

    when(() => store.persist(any())).thenAnswer((inv) async {
      final image = inv.positionalArguments.single as CapturedImage;
      return NewUpload(
        filePath: '/docs/${image.name}',
        fileName: image.name,
        sizeBytes: image.sizeBytes,
      );
    });
    when(() => store.delete(any())).thenAnswer((_) async {});
    when(() => queue.enqueueBatch(any())).thenAnswer((_) async => batch);
    when(() => scheduler.requestSync()).thenAnswer((_) async {});
  });

  test('stores every image, queues one batch and requests a sync', () async {
    final result = await enqueue(images);

    expect(result, batch);
    final queued =
        verify(() => queue.enqueueBatch(captureAny())).captured.single
            as List<NewUpload>;
    expect(queued.map((u) => u.filePath), ['/docs/a.jpg', '/docs/b.jpg']);
    verify(() => scheduler.requestSync()).called(1);
  });

  test('removes the original photos only after the batch is queued', () async {
    await enqueue(images);

    verifyInOrder([
      () => queue.enqueueBatch(any()),
      () => store.delete('/cache/a.jpg'),
      () => store.delete('/cache/b.jpg'),
    ]);
  });

  test('rejects an empty batch', () {
    expect(() => enqueue(const []), throwsArgumentError);
  });

  test('removes stored files when queueing fails', () async {
    when(() => queue.enqueueBatch(any())).thenThrow(StateError('db'));

    await expectLater(enqueue(images), throwsStateError);

    verify(() => store.delete('/docs/a.jpg')).called(1);
    verify(() => store.delete('/docs/b.jpg')).called(1);
    verifyNever(() => store.delete('/cache/a.jpg'));
    verifyNever(() => store.delete('/cache/b.jpg'));
    verifyNever(() => scheduler.requestSync());
  });

  test('a scheduling failure does not fail the queued batch', () async {
    when(() => scheduler.requestSync()).thenThrow(StateError('wm'));

    expect(await enqueue(images), batch);
  });
}
