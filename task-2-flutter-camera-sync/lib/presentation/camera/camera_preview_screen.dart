import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/camera_preview_source.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import 'camera_cubit.dart';
import 'camera_state.dart';
import 'widgets/camera_icon_button.dart';
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
    required this.onClose,
    required this.onOpenOptions,
  });

  final CameraPreviewSource previewSource;
  final VoidCallback onOpenUploads;
  final VoidCallback onClose;
  final VoidCallback onOpenOptions;

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
      body: BlocConsumer<CameraCubit, CameraState>(
        listenWhen: (previous, current) =>
            current.feedback != CameraFeedback.none &&
            previous.feedback != current.feedback,
        listener: _onFeedback,
        builder: (context, state) {
          final cubit = context.read<CameraCubit>();
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: _content(context, state, cubit)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      CameraIconButton(
                        icon: Icons.close,
                        label: AppStrings.closeCamera,
                        onPressed: widget.onClose,
                      ),
                      const Spacer(),
                      if (state.isReady && state.hasFlash) ...[
                        CameraIconButton(
                          icon: state.flashOn
                              ? Icons.flash_on
                              : Icons.flash_off,
                          label: state.flashOn
                              ? AppStrings.flashOn
                              : AppStrings.flashOff,
                          active: state.flashOn,
                          onPressed: cubit.toggleFlash,
                        ),
                        const SizedBox(width: 8),
                      ],
                      CameraIconButton(
                        icon: Icons.settings_outlined,
                        label: AppStrings.cameraOptions,
                        onPressed: widget.onOpenOptions,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, CameraState state, CameraCubit cubit) {
    return switch (state.status) {
      CameraStatus.initializing => const _Starting(),
      CameraStatus.ready => _CameraView(
        state: state,
        previewSource: widget.previewSource,
        onOpenUploads: widget.onOpenUploads,
      ),
      CameraStatus.permissionDenied => CameraMessageView(
        icon: Icons.no_photography_outlined,
        title: AppStrings.permissionDeniedTitle,
        body: AppStrings.permissionDeniedBody,
        actionLabel: AppStrings.grantPermission,
        onAction: cubit.initialize,
      ),
      CameraStatus.permissionPermanentlyDenied => CameraMessageView(
        icon: Icons.lock_outline,
        title: AppStrings.permissionBlockedTitle,
        body: AppStrings.permissionBlockedBody,
        actionLabel: AppStrings.openSettings,
        onAction: cubit.openSettings,
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
        onAction: cubit.initialize,
      ),
    };
  }

  void _onFeedback(BuildContext context, CameraState state) {
    final cubit = context.read<CameraCubit>();
    final feedback = state.feedback;
    cubit.feedbackShown();
    // A queued batch is confirmed by showing it in the upload manager.
    if (feedback == CameraFeedback.batchQueued) {
      widget.onOpenUploads();
      return;
    }
    final message = switch (feedback) {
      CameraFeedback.captureFailed => AppStrings.captureFailed,
      CameraFeedback.queueFailed => AppStrings.queueFailed,
      CameraFeedback.flipFailed => AppStrings.flipFailed,
      CameraFeedback.batchQueued || CameraFeedback.none => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
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
  const _CameraView({
    required this.state,
    required this.previewSource,
    required this.onOpenUploads,
  });

  final CameraState state;
  final CameraPreviewSource previewSource;
  final VoidCallback onOpenUploads;

  /// Room for the top bar (48dp buttons plus padding).
  static const double _topBarSpace = 64;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CameraCubit>();
    final capabilities = state.capabilities!;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              // The preview fills the screen like a "cover" image; the part
              // beyond the screen is cropped, so tap positions are mapped
              // back to the full preview.
              final aspect = previewSource.aspectRatio;
              final width = math.max(size.width, size.height * aspect);
              final height = width / aspect;
              final cropX = (width - size.width) / 2;
              final cropY = (height - size.height) / 2;
              final focus = state.focus;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  cubit.focusAt(
                    Offset(
                      (details.localPosition.dx + cropX) / width,
                      (details.localPosition.dy + cropY) / height,
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
                    Positioned(
                      left: -cropX,
                      top: -cropY,
                      width: width,
                      height: height,
                      child: previewSource.buildPreview(),
                    ),
                    if (focus != null)
                      FocusIndicator(
                        id: focus.id,
                        center: Offset(
                          focus.position.dx * width - cropX,
                          focus.position.dy * height - cropY,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: _topBarSpace),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ZoomSlider(
                      min: capabilities.min,
                      max: capabilities.max,
                      value: state.zoom,
                      onChanged: cubit.setZoom,
                    ),
                  ),
                ),
              ),
              ZoomPresetButtons(
                presets: capabilities.presets,
                zoom: state.zoom,
                onSelected: cubit.setZoom,
              ),
              const SizedBox(height: 20),
              CaptureBar(
                batch: state.batch,
                canCapture: state.canCapture,
                onCapture: cubit.capture,
                onOpenUploads: onOpenUploads,
                onFlip: state.canFlip ? cubit.flipCamera : null,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.icon(
                  onPressed: state.canQueue ? cubit.queueBatch : null,
                  icon: state.isQueueing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(
                    (state.batch.isEmpty
                            ? AppStrings.uploadBatchEmpty
                            : AppStrings.uploadBatch(state.batch.length))
                        .toUpperCase(),
                    style: AppTheme.label(context).copyWith(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
