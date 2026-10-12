import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/strings.dart';
import '../presentation/camera/camera_cubit.dart';
import '../presentation/camera/camera_preview_screen.dart';
import '../presentation/upload_manager/upload_manager_screen.dart';
import '../presentation/upload_manager/upload_queue_cubit.dart';
import 'di.dart';

class PinpointApp extends StatelessWidget {
  const PinpointApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => CameraCubit(
          dependencies.camera,
          dependencies.cameraPermission,
          dependencies.enqueueBatch,
        )..initialize(),
        child: Builder(
          builder: (context) => CameraPreviewScreen(
            previewSource: dependencies.cameraPreview,
            onOpenUploads: () => _openUploads(context),
          ),
        ),
      ),
    );
  }

  void _openUploads(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => BlocProvider(
          create: (_) => UploadQueueCubit(
            queue: dependencies.queue,
            connectivity: dependencies.connectivity,
            scheduler: dependencies.scheduler,
            modeStore: dependencies.modeStore,
            changeBus: dependencies.changeBus,
            imageStore: dependencies.imageStore,
          )..initialize(),
          child: UploadManagerScreen(
            onStartNewBatch: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
    );
  }
}
