import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinpoint_capture/core/strings.dart';
import 'package:pinpoint_capture/core/theme.dart';
import 'package:pinpoint_capture/domain/entities/pending_upload.dart';
import 'package:pinpoint_capture/domain/entities/upload_status.dart';
import 'package:pinpoint_capture/domain/repositories/upload_queue_repository.dart';
import 'package:pinpoint_capture/domain/services/connectivity_service.dart';
import 'package:pinpoint_capture/domain/services/image_store.dart';
import 'package:pinpoint_capture/domain/services/queue_change_bus.dart';
import 'package:pinpoint_capture/domain/services/sync_pause_store.dart';
import 'package:pinpoint_capture/domain/services/sync_scheduler.dart';
import 'package:pinpoint_capture/domain/usecases/add_sample_batch_use_case.dart';
import 'package:pinpoint_capture/domain/usecases/clear_synced_use_case.dart';
import 'package:pinpoint_capture/presentation/upload_manager/upload_manager_screen.dart';
import 'package:pinpoint_capture/presentation/upload_manager/upload_queue_cubit.dart';

class MockQueue extends Mock implements UploadQueueRepository {}

class MockConnectivity extends Mock implements ConnectivityService {}

class MockScheduler extends Mock implements SyncScheduler {}

class MockPauseStore extends Mock implements SyncPauseStore {}

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
  late MockPauseStore pauseStore;
  late MockBus bus;
  late MockImageStore imageStore;
  var rows = <PendingUpload>[];
  var isOnline = true;
  var startNewBatchTaps = 0;
  var mockModeOpened = 0;

  setUp(() {
    rows = [];
    isOnline = true;
    startNewBatchTaps = 0;
    mockModeOpened = 0;
    queue = MockQueue();
    connectivity = MockConnectivity();
    scheduler = MockScheduler();
    pauseStore = MockPauseStore();
    bus = MockBus();
    imageStore = MockImageStore();
    when(() => queue.getAll()).thenAnswer((_) async => rows);
    when(() => queue.clearSynced()).thenAnswer((_) async => <String>[]);
    when(() => connectivity.isOnline()).thenAnswer((_) async => isOnline);
    when(() => connectivity.onlineChanges)
        .thenAnswer((_) => const Stream<bool>.empty());
    when(() => bus.changes).thenAnswer((_) => const Stream<void>.empty());
    when(() => pauseStore.isPaused()).thenAnswer((_) async => false);
    when(() => pauseStore.write(any())).thenAnswer((_) async {});
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
      pauseStore: pauseStore,
      changeBus: bus,
      clearSynced: ClearSyncedUseCase(queue, imageStore),
      addSampleBatch: AddSampleBatchUseCase(queue, scheduler),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: BlocProvider.value(
          value: cubit,
          child: UploadManagerScreen(
            onStartNewBatch: () => startNewBatchTaps++,
            onOpenMockMode: () => mockModeOpened++,
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

  String caps(String text) => text.toUpperCase();

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

    expect(find.text(caps(AppStrings.statusUploading)), findsOneWidget);
    expect(find.text(caps(AppStrings.statusRetrying(3))), findsOneWidget);
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text(caps(AppStrings.statusWaiting)), findsOneWidget);
    expect(find.text(caps(AppStrings.statusSynced)), findsOneWidget);
    expect(
      find.text(caps('${AppStrings.pendingUploadsHeader} (3)')),
      findsOneWidget,
    );
    expect(find.text(caps('${AppStrings.syncedHeader} (1)')), findsOneWidget);
  });

  testWidgets('shows progress as size and percent', (tester) async {
    rows = [upload(1, UploadStatus.synced), upload(2, UploadStatus.waiting)];
    await pumpScreen(tester);

    expect(find.text('50%'), findsOneWidget);
    expect(
      find.text(AppStrings.sizeProgress('1.5 MB', '3.0 MB')),
      findsOneWidget,
    );
  });

  testWidgets('offline shows the chip and a waiting-for-connection reason', (
    tester,
  ) async {
    isOnline = false;
    rows = [upload(1, UploadStatus.waiting)];
    await pumpScreen(tester);

    expect(find.text(caps(AppStrings.offline)), findsOneWidget);
    expect(find.text(caps(AppStrings.statusWaitingOffline)), findsOneWidget);
  });

  testWidgets('online chip says stable link', (tester) async {
    await pumpScreen(tester);

    expect(find.text(caps(AppStrings.online)), findsOneWidget);
  });

  testWidgets('Pause all pauses and the button becomes Resume', (tester) async {
    rows = [upload(1, UploadStatus.waiting), upload(2, UploadStatus.waiting)];
    await pumpScreen(tester);

    await tester.tap(find.text(caps(AppStrings.pauseAll)));
    await tester.pump();

    verify(() => pauseStore.write(true)).called(1);
    expect(find.text(caps(AppStrings.resumeAll)), findsOneWidget);
    expect(find.text(caps(AppStrings.statusPaused)), findsNWidgets(2));
  });

  testWidgets('Resume restarts the worker immediately', (tester) async {
    when(() => pauseStore.isPaused()).thenAnswer((_) async => true);
    rows = [upload(1, UploadStatus.waiting)];
    await pumpScreen(tester);

    await tester.tap(find.text(caps(AppStrings.resumeAll)));
    await tester.pump();

    verify(() => pauseStore.write(false)).called(1);
    verify(() => scheduler.requestSync(immediate: true)).called(1);
    expect(find.text(caps(AppStrings.pauseAll)), findsOneWidget);
  });

  testWidgets('Pause all is hidden once everything is synced', (tester) async {
    rows = [upload(1, UploadStatus.synced), upload(2, UploadStatus.synced)];
    await pumpScreen(tester);

    expect(find.text(caps(AppStrings.pauseAll)), findsNothing);
    expect(find.text(caps(AppStrings.resumeAll)), findsNothing);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('menu Retry now requests an immediate sync', (tester) async {
    rows = [upload(1, UploadStatus.retrying, attempts: 1, error: 'x')];
    await pumpScreen(tester);

    await tester.tap(find.byTooltip(AppStrings.moreOptions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.retryNow));
    await tester.pump();

    verify(() => scheduler.requestSync(immediate: true)).called(1);
    expect(find.text(AppStrings.feedbackRetrying), findsOneWidget);
  });

  testWidgets('menu opens the mock result picker', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip(AppStrings.moreOptions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.menuMockMode));
    await tester.pumpAndSettle();

    expect(mockModeOpened, 1);
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
