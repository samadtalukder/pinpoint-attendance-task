import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/strings.dart';
import '../presentation/camera/camera_cubit.dart';
import '../presentation/camera/camera_preview_screen.dart';
import 'di.dart';

class PinpointApp extends StatelessWidget {
  const PinpointApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => CameraCubit(
          dependencies.camera,
          dependencies.cameraPermission,
          dependencies.enqueueBatch,
        )..initialize(),
        child: CameraPreviewScreen(
          previewSource: dependencies.cameraPreview,
          onOpenUploads: () {},
        ),
      ),
    );
  }
}
