import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../core/camera_preview_source.dart';
import '../../core/constants.dart';
import '../../domain/entities/captured_image.dart';
import '../../domain/entities/zoom_capabilities.dart';
import '../../domain/services/camera_service.dart';
import 'lens_info_source.dart';
import 'ultrawide_detection.dart';

/// Adapter over the `camera` plugin.
///
/// Ultrawide is supported two ways: a logical multi-camera that reports a
/// zoom below 1 (handled by plain zoom), or a separate ultrawide back camera
/// (handled by switching lens). Below 1x on a separate lens the zoom snaps
/// to 0.5x.
class CameraPluginService implements CameraService, CameraPreviewSource {
  CameraPluginService({LensInfoSource? lensInfo})
    : _lensInfo = lensInfo ?? MethodChannelLensInfoSource();

  final LensInfoSource _lensInfo;
  CameraController? _controller;
  CameraDescription? _main;
  CameraDescription? _ultraWide;
  double _mainMinZoom = ZoomConstants.main;
  double _mainMaxZoom = ZoomConstants.main;
  bool _canFlip = false;

  @override
  bool get canFlip => _canFlip;

  @override
  Future<ZoomCapabilities> initialize({
    CameraLens lens = CameraLens.back,
  }) async {
    await dispose();
    try {
      final all = await availableCameras();
      final direction = lens == CameraLens.back
          ? CameraLensDirection.back
          : CameraLensDirection.front;
      _canFlip =
          all.any((c) => c.lensDirection == CameraLensDirection.back) &&
          all.any((c) => c.lensDirection == CameraLensDirection.front);
      final candidates = all.where((c) => c.lensDirection == direction);
      if (candidates.isEmpty) {
        throw const CameraFailure(CameraFailureType.noCamera);
      }
      final list = candidates.toList();
      _main = list.firstWhere(
        (c) => c.lensType != CameraLensType.ultraWide,
        orElse: () => list.first,
      );
      _ultraWide = lens == CameraLens.back
          ? findUltraWide(
              back: list,
              main: _main!,
              equivalentMm: await _lensInfo.equivalentFocalLengths(),
            )
          : null;

      final controller = CameraController(
        _main!,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();

      _mainMinZoom = await controller.getMinZoomLevel();
      _mainMaxZoom = await controller.getMaxZoomLevel();
      if (_mainMinZoom <= ZoomConstants.ultraWide) _ultraWide = null;

      return ZoomCapabilities(
        min: _ultraWide != null ? ZoomConstants.ultraWide : _mainMinZoom,
        max: _mainMaxZoom,
      );
    } on CameraException catch (e) {
      await dispose();
      throw CameraFailure(CameraFailureType.unavailable, e.code);
    }
  }

  @override
  Future<void> setFlash(bool on) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFlashMode(on ? FlashMode.always : FlashMode.off);
    } on CameraException {
      // Lenses without a flash reject the mode; photos still work.
    }
  }

  @override
  Future<void> setZoom(double zoom) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final ultraWide = _ultraWide;
      if (ultraWide != null && zoom < ZoomConstants.main) {
        await _useLens(controller, ultraWide);
        return;
      }
      await _useLens(controller, _main!);
      await controller.setZoomLevel(zoom.clamp(_mainMinZoom, _mainMaxZoom));
    } on CameraException {
      // Zoom is best effort; keep the preview running.
    }
  }

  Future<void> _useLens(
    CameraController controller,
    CameraDescription lens,
  ) async {
    if (controller.description != lens) await controller.setDescription(lens);
  }

  @override
  Future<void> focusAt(double x, double y) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final point = Offset(x, y);
    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
    } on CameraException {
      // Fixed-focus lenses reject focus points; the indicator still shows.
    }
  }

  @override
  Future<CapturedImage> capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CameraFailure(CameraFailureType.unavailable);
    }
    try {
      final file = await controller.takePicture();
      return CapturedImage(
        path: file.path,
        name: p.basename(file.path),
        sizeBytes: await File(file.path).length(),
      );
    } on CameraException catch (e) {
      throw CameraFailure(CameraFailureType.unavailable, e.code);
    }
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  @override
  double get aspectRatio {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return ZoomConstants.fallbackPreviewAspect;
    }
    final landscape = controller.value.aspectRatio;
    return landscape > 1 ? 1 / landscape : landscape;
  }

  @override
  Widget buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return CameraPreview(controller);
  }
}
