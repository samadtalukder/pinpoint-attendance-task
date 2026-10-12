import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinpoint_capture/core/strings.dart';
import 'package:pinpoint_capture/domain/entities/pending_upload.dart';
import 'package:pinpoint_capture/domain/entities/upload_status.dart';
import 'package:pinpoint_capture/domain/repositories/upload_queue_repository.dart';
import 'package:pinpoint_capture/domain/services/connectivity_service.dart';
import 'package:pinpoint_capture/domain/services/image_store.dart';
import 'package:pinpoint_capture/domain/services/mock_upload_mode_store.dart';
import 'package:pinpoint_capture/domain/services/queue_change_bus.dart';
import 'package:pinpoint_capture/domain/services/sync_scheduler.dart';
import 'package:pinpoint_capture/presentation/upload_manager/upload_manager_screen.dart';
import 'package:pinpoint_capture/presentation/upload_manager/upload_queue_cubit.dart';

class MockQueue extends Mock implements UploadQueueRepository {}

class MockConnectivity extends Mock implements ConnectivityService {}

class MockScheduler extends Mock implements SyncScheduler {}

class MockModeStore extends Mock implements MockUploadModeStore {}

class MockBus extends Mock implements QueueChangeBus {}

class MockImageStore extends Mock implements ImageStore {}

PendingUpload upload(
  int id,
  UploadStatus status, {
  int attempts = 0,
  String? error,
  int size = 1500000,
}) => PendingUpload(
  id: id,
  batchId: 1,
  filePath: '/none/$id.jpg',
  fileName: 'IMG_$id.jpg',
  sizeBytes: size,
  status: status,
  attempts: attempts,
  lastError: error,
  createdAt: DateTime(2026, 10, 12),
);

void main() {
  late MockQueue queue;
  late MockConnectivity connectivity;
  late MockScheduler scheduler;
  late MockModeStore modeStore;
  late MockBus bus;
  late MockImageStore imageStore;
  var rows = <PendingUpload>[];
  var isOnline = true;
  var startNewBatchTaps = 0;

  setUpAll(() => registerFallbackValue(MockUploadMode.success));

  setUp(() {
    rows = [];
    isOnline = true;
    startNewBatchTaps = 0;
    queue = MockQueue();
    connectivity = MockConnectivity();
    scheduler = MockScheduler();
    modeStore = MockModeStore();
    bus = MockBus();
    imageStore = MockImageStore();
    when(() => queue.getAll()).thenAnswer((_) async => rows);
    when(() => queue.clearSynced()).thenAnswer((_) async => <String>[]);
    when(() => connectivity.isOnline()).thenAnswer((_) async => isOnline);
    when(() => connectivity.onlineChanges)
        .thenAnswer((_) => const Stream<bool>.empty());
    when(() => bus.changes).thenAnswer((_) => const Stream<void>.empty());
    when(() => modeStore.read())
        .thenAnswer((_) async => MockUploadMode.success);
    when(() => modeStore.write(any())).thenAnswer((_) async {});
    when(() => scheduler.requestSync(immediate: any(named: 'immediate')))
        .thenAnswer((_) async {});
    when(() => imageStore.delete(any())).thenAnswer((_) async {});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = UploadQueueCubit(
      queue: queue,
      connectivity: connectivity,
      scheduler: scheduler,
      modeStore: modeStore,
      changeBus: bus,
      imageStore: imageStore,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: UploadManagerScreen(
            onStartNewBatch: () => startNewBatchTaps++,
          ),
        ),
      ),
    );
    await cubit.initialize();
    await tester.pump();
  }

  testWidgets('empty queue explains itself and offers a new batch', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text(AppStrings.emptyTitle), findsOneWidget);
    expect(find.text(AppStrings.emptyBody), findsOneWidget);

    await tester.tap(find.text(AppStrings.startNewBatch));
    expect(startNewBatchTaps, 1);
  });

  testWidgets('lists every status with text, not only color', (tester) async {
    rows = [
      upload(1, UploadStatus.uploading),
      upload(
        2,
        UploadStatus.retrying,
        attempts: 3,
        error: 'No internet connection',
      ),
      upload(3, UploadStatus.waiting),
      upload(4, UploadStatus.synced),
    ];
    await pumpScreen(tester);

    expect(find.text(AppStrings.statusUploading), findsOneWidget);
    expect(find.text(AppStrings.statusRetrying(3)), findsOneWidget);
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text(AppStrings.statusWaiting), findsOneWidget);
    expect(find.text(AppStrings.statusSynced), findsOneWidget);
    expect(find.text('${AppStrings.pendingUploadsHeader} (3)'), findsOneWidget);
    expect(find.text('${AppStrings.syncedHeader} (1)'), findsOneWidget);
  });

  testWidgets('shows progress as count, size and percent', (tester) async {
    rows = [upload(1, UploadStatus.synced), upload(2, UploadStatus.waiting)];
    await pumpScreen(tester);

    expect(find.text('50%'), findsOneWidget);
    expect(find.textContaining('1 of 2 uploaded'), findsOneWidget);
    expect(find.textContaining('1.5 MB / 3.0 MB'), findsOneWidget);
  });

  testWidgets('offline shows the chip and a waiting-for-connection reason', (
    tester,
  ) async {
    isOnline = false;
    rows = [upload(1, UploadStatus.waiting)];
    await pumpScreen(tester);

    expect(find.text(AppStrings.offline), findsOneWidget);
    expect(find.text(AppStrings.statusWaitingOffline), findsOneWidget);
  });

  testWidgets('Retry now requests an immediate sync', (tester) async {
    rows = [upload(1, UploadStatus.retrying, attempts: 1, error: 'x')];
    await pumpScreen(tester);

    await tester.tap(find.text(AppStrings.retryNow));
    await tester.pump();

    verify(() => scheduler.requestSync(immediate: true)).called(1);
    expect(find.text(AppStrings.feedbackRetrying), findsOneWidget);
  });

  testWidgets('Retry now is disabled when nothing is pending', (tester) async {
    rows = [upload(1, UploadStatus.synced)];
    await pumpScreen(tester);

    final button = tester.widget<TextButton>(
      find.ancestor(
        of: find.text(AppStrings.retryNow),
        matching: find.byType(TextButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('menu switches the mock upload result', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip(AppStrings.moreOptions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.mockFailure));
    await tester.pumpAndSettle();

    verify(() => modeStore.write(MockUploadMode.failure)).called(1);
  });

  testWidgets('menu clears synced uploads', (tester) async {
    rows = [upload(1, UploadStatus.synced)];
    await pumpScreen(tester);

    await tester.tap(find.byTooltip(AppStrings.moreOptions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.clearSynced));
    await tester.pumpAndSettle();

    verify(() => queue.clearSynced()).called(1);
  });
}
