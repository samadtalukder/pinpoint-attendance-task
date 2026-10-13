import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:pinpoint_capture/app/app.dart';
import 'package:pinpoint_capture/app/di.dart';
import 'package:pinpoint_capture/core/strings.dart';
import 'package:pinpoint_capture/data/db/app_database.dart';
import 'package:pinpoint_capture/data/files/local_image_store.dart';
import 'package:pinpoint_capture/data/repositories/sqflite_upload_queue_repository.dart';
import 'package:pinpoint_capture/data/services/isolate_queue_change_bus.dart';
import 'package:pinpoint_capture/data/services/mock_upload_api.dart';
import 'package:pinpoint_capture/domain/usecases/process_upload_queue_use_case.dart';
import 'package:pinpoint_capture/presentation/camera/widgets/zoom_preset_buttons.dart';
import 'package:sqflite/sqflite.dart';

import 'support/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'capture a batch, upload fails, queue persists, upload succeeds',
    (tester) async {
      final workDir = await Directory.systemTemp.createTemp('pinpoint_it');
      addTearDown(() => workDir.delete(recursive: true));
      final dbPath = p.join(workDir.path, 'queue.db');
      final camera = FakeCameraService(workDir);
      final modeStore = InMemoryModeStore(); // starts in failure mode
      final pauseStore = InMemoryPauseStore();
      final scheduler = RecordingSyncScheduler();
      final connectivity = FakeConnectivityService();

      // Builds the app the way a process start would: same files, same
      // preferences, fresh objects.
      Future<(AppDependencies, Database)> startApp() async {
        final db = await AppDatabase.open(path: dbPath);
        final queue = SqfliteUploadQueueRepository(db);
        final changeBus = IsolateQueueChangeBus();
        final api = MockUploadApi(modeStore, delay: (_) async {});
        final deps = AppDependencies(
          queue: queue,
          uploadApi: api,
          modeStore: modeStore,
          pauseStore: pauseStore,
          connectivity: connectivity,
          scheduler: scheduler,
          changeBus: changeBus,
          camera: camera,
          cameraPreview: camera,
          cameraPermission: FakePermissionService(),
          imageStore: LocalImageStore(() async => workDir),
        );
        await tester.pumpWidget(PinpointApp(dependencies: deps));
        await tester.pumpAndSettle();
        return (deps, db);
      }

      var (deps, db) = await startApp();

      // Capture two photos and queue them as one batch.
      expect(
        find.descendant(
          of: find.byType(ZoomPresetButtons),
          matching: find.text('0.5x'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('shutter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shutter')));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.uploadBatch(2).toUpperCase()),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.uploadBatch(2).toUpperCase()));
      await tester.pumpAndSettle();
      // Queueing lands on the upload manager.
      expect(find.text(AppStrings.uploadsTitle), findsOneWidget);
      expect(scheduler.requests, [false], reason: 'a sync was requested');

      // The worker runs while the network is down: the upload fails.
      expect(await deps.processUploadQueue(), SyncResult.failed);

      // Process restart: the old UI dies, new objects open the same database.
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
      (deps, db) = await startApp();
      addTearDown(db.close);

      await tester.tap(find.byKey(const Key('batch_thumbnail')));
      await tester.pumpAndSettle();
      expect(
        find.text('${AppStrings.pendingUploadsHeader} (2)'.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.statusRetrying(1).toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text(AppStrings.statusSynced.toUpperCase()), findsNothing);

      // Pause all: the worker leaves the queue alone.
      await tester.tap(find.text(AppStrings.pauseAll.toUpperCase()));
      await tester.pumpAndSettle();
      expect(await deps.processUploadQueue(), SyncResult.paused);
      expect(await deps.queue.getUnsynced(), hasLength(2));

      // Connection comes back: flip the mock to success from the manager's
      // menu, resume, and the worker drains the queue.
      await tester.tap(find.byTooltip(AppStrings.moreOptions));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.menuMockMode));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.mockSuccess));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.resumeAll.toUpperCase()));
      await tester.pumpAndSettle();

      expect(await deps.processUploadQueue(), SyncResult.completed);
      await tester.pumpAndSettle();

      expect(
        find.text('${AppStrings.pendingUploadsHeader} (2)'.toUpperCase()),
        findsNothing,
      );
      expect(
        find.text('${AppStrings.syncedHeader} (2)'.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.statusSynced.toUpperCase()),
        findsNWidgets(2),
      );
      expect(find.text('100%'), findsOneWidget);
      expect(await deps.queue.getUnsynced(), isEmpty);
    },
  );
}
