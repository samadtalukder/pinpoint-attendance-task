import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/camera_preview_source.dart';
import '../../core/strings.dart';
import 'camera_cubit.dart';
import 'camera_state.dart';
import 'widgets/camera_message_view.dart';
import 'widgets/capture_bar.dart';
import 'widgets/focus_indicator.dart';
import 'widgets/zoom_preset_buttons.dart';
import 'widgets/zoom_slider.dart';

/// Custom camera: pinch / slider / preset zoom, tap to focus, batch capture.
/// Expects a [CameraCubit] above it that is already initializing.
class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({
    super.key,
    required this.previewSource,
    required this.onOpenUploads,
  });

  final CameraPreviewSource previewSource;
  final VoidCallback onOpenUploads;

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<CameraCubit>();
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        cubit.onAppPaused();
      case AppLifecycleState.resumed:
        cubit.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            tooltip: AppStrings.openUploads,
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: widget.onOpenUploads,
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<CameraCubit, CameraState>(
          listenWhen: (previous, current) =>
              current.feedback != CameraFeedback.none &&
              previous.feedback != current.feedback,
          listener: _showFeedback,
          builder: (context, state) => switch (state.status) {
            CameraStatus.initializing => const _Starting(),
            CameraStatus.ready => _CameraView(
              state: state,
              previewSource: widget.previewSource,
            ),
            CameraStatus.permissionDenied => CameraMessageView(
              icon: Icons.no_photography_outlined,
              title: AppStrings.permissionDeniedTitle,
              body: AppStrings.permissionDeniedBody,
              actionLabel: AppStrings.grantPermission,
              onAction: context.read<CameraCubit>().initialize,
            ),
            CameraStatus.permissionPermanentlyDenied => CameraMessageView(
              icon: Icons.lock_outline,
              title: AppStrings.permissionBlockedTitle,
              body: AppStrings.permissionBlockedBody,
              actionLabel: AppStrings.openSettings,
              onAction: context.read<CameraCubit>().openSettings,
            ),
            CameraStatus.noCamera => const CameraMessageView(
              icon: Icons.videocam_off_outlined,
              title: AppStrings.noCameraTitle,
              body: AppStrings.noCameraBody,
            ),
            CameraStatus.error => CameraMessageView(
              icon: Icons.error_outline,
              title: AppStrings.cameraErrorTitle,
              body: AppStrings.cameraErrorBody,
              actionLabel: AppStrings.tryAgain,
              onAction: context.read<CameraCubit>().initialize,
            ),
          },
        ),
      ),
    );
  }

  void _showFeedback(BuildContext context, CameraState state) {
    final message = switch (state.feedback) {
      CameraFeedback.captureFailed => AppStrings.captureFailed,
      CameraFeedback.queueFailed => AppStrings.queueFailed,
      CameraFeedback.batchQueued => AppStrings.batchQueued(
        state.lastQueuedCount,
      ),
      CameraFeedback.flipFailed => AppStrings.flipFailed,
      CameraFeedback.none => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    context.read<CameraCubit>().feedbackShown();
  }
}

class _Starting extends StatelessWidget {
  const _Starting();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            AppStrings.cameraStarting,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({required this.state, required this.previewSource});

  final CameraState state;
  final CameraPreviewSource previewSource;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CameraCubit>();
    final capabilities = state.capabilities!;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final focus = state.focus;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  cubit.focusAt(
                    Offset(
                      details.localPosition.dx / size.width,
                      details.localPosition.dy / size.height,
                    ),
                  );
                },
                onScaleStart: (_) => cubit.pinchStarted(),
                onScaleUpdate: (details) {
                  if (details.pointerCount >= 2) {
                    cubit.pinchUpdated(details.scale);
                  }
                },
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: Center(child: previewSource.buildPreview()),
                    ),
                    if (focus != null)
                      FocusIndicator(
                        id: focus.id,
                        center: Offset(
                          focus.position.dx * size.width,
                          focus.position.dy * size.height,
                        ),
                      ),
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: ZoomSlider(
                          min: capabilities.min,
                          max: capabilities.max,
                          value: state.zoom,
                          onChanged: cubit.setZoom,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.zoomValue(state.zoom.toStringAsFixed(1)),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        ZoomPresetButtons(
          presets: capabilities.presets,
          zoom: state.zoom,
          onSelected: cubit.setZoom,
        ),
        const SizedBox(height: 16),
        CaptureBar(
          batch: state.batch,
          canCapture: state.canCapture,
          onCapture: cubit.capture,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: state.canQueue ? cubit.queueBatch : null,
              icon: state.isQueueing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload),
              label: Text(
                state.batch.isEmpty
                    ? AppStrings.uploadBatchEmpty
                    : AppStrings.uploadBatch(state.batch.length),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
