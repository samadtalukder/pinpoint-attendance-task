import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/camera_preview_source.dart';
import '../data/db/app_database.dart';
import '../data/files/local_image_store.dart';
import '../data/repositories/sqflite_upload_queue_repository.dart';
import '../data/services/camera_plugin_service.dart';
import '../data/services/connectivity_plus_service.dart';
import '../data/services/isolate_queue_change_bus.dart';
import '../data/services/mock_upload_api.dart';
import '../data/services/permission_handler_camera_permission_service.dart';
import '../data/services/shared_prefs_mock_upload_mode_store.dart';
import '../data/services/workmanager_sync_scheduler.dart';
import '../domain/repositories/upload_queue_repository.dart';
import '../domain/services/camera_permission_service.dart';
import '../domain/services/camera_service.dart';
import '../domain/services/connectivity_service.dart';
import '../domain/services/image_store.dart';
import '../domain/services/mock_upload_mode_store.dart';
import '../domain/services/queue_change_bus.dart';
import '../domain/services/sync_scheduler.dart';
import '../domain/services/upload_api.dart';
import '../domain/usecases/enqueue_batch_use_case.dart';
import '../domain/usecases/process_upload_queue_use_case.dart';
import '../domain/usecases/sync_coordinator.dart';

/// Composition root: the only place that picks implementations. Built once in
/// the UI isolate and once per worker run.
class AppDependencies {
  AppDependencies._({
    required this.queue,
    required this.uploadApi,
    required this.modeStore,
    required this.connectivity,
    required this.scheduler,
    required this.changeBus,
    required this.camera,
    required this.cameraPreview,
    required this.cameraPermission,
    required this.imageStore,
  }) : enqueueBatch = EnqueueBatchUseCase(imageStore, queue, scheduler),
       processUploadQueue = ProcessUploadQueueUseCase(queue, uploadApi),
       syncCoordinator = SyncCoordinator(queue, connectivity, scheduler);

  final UploadQueueRepository queue;
  final UploadApi uploadApi;
  final MockUploadModeStore modeStore;
  final ConnectivityService connectivity;
  final SyncScheduler scheduler;
  final QueueChangeBus changeBus;
  final CameraService camera;
  final CameraPreviewSource cameraPreview;
  final CameraPermissionService cameraPermission;
  final ImageStore imageStore;
  final EnqueueBatchUseCase enqueueBatch;
  final ProcessUploadQueueUseCase processUploadQueue;
  final SyncCoordinator syncCoordinator;

  /// The database is deliberately never closed: when the worker runs inside
  /// the UI engine, sqflite hands out the same connection to both.
  static Future<AppDependencies> create() async {
    final db = await AppDatabase.open();
    final modeStore = SharedPrefsMockUploadModeStore();
    final camera = CameraPluginService();
    return AppDependencies._(
      queue: SqfliteUploadQueueRepository(db),
      uploadApi: MockUploadApi(modeStore),
      modeStore: modeStore,
      connectivity: ConnectivityPlusService(),
      scheduler: WorkmanagerSyncScheduler(),
      changeBus: IsolateQueueChangeBus(),
      camera: camera,
      cameraPreview: camera,
      cameraPermission: PermissionHandlerCameraPermissionService(),
      imageStore: LocalImageStore(getApplicationDocumentsDirectory),
    );
  }
}
