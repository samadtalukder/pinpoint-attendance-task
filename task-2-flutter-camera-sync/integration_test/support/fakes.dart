import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pinpoint_capture/core/camera_preview_source.dart';
import 'package:pinpoint_capture/domain/entities/captured_image.dart';
import 'package:pinpoint_capture/domain/entities/zoom_capabilities.dart';
import 'package:pinpoint_capture/domain/services/camera_permission_service.dart';
import 'package:pinpoint_capture/domain/services/camera_service.dart';
import 'package:pinpoint_capture/domain/services/connectivity_service.dart';
import 'package:pinpoint_capture/domain/services/mock_upload_mode_store.dart';
import 'package:pinpoint_capture/domain/services/sync_pause_store.dart';
import 'package:pinpoint_capture/domain/services/sync_scheduler.dart';

/// Camera that "takes" a tiny file in [directory]. No hardware involved.
class FakeCameraService implements CameraService, CameraPreviewSource {
  FakeCameraService(this.directory);

  final Directory directory;
  int _shots = 0;

  @override
  bool get canFlip => true;

  @override
  Future<ZoomCapabilities> initialize({
    CameraLens lens = CameraLens.back,
  }) async => const ZoomCapabilities(min: 0.5, max: 8);

  @override
  Future<void> setFlash(bool on) async {}

  @override
  Future<void> setZoom(double zoom) async {}

  @override
  Future<void> focusAt(double x, double y) async {}

  @override
  Future<CapturedImage> capture() async {
    final file = File(p.join(directory.path, 'CAP_${++_shots}.jpg'));
    await file.writeAsBytes(List<int>.filled(2048, 7));
    return CapturedImage(
      path: file.path,
      name: p.basename(file.path),
      sizeBytes: 2048,
    );
  }

  @override
  Future<void> dispose() async {}

  @override
  double get aspectRatio => 9 / 16;

  @override
  Widget buildPreview() => const SizedBox.expand(
    child: ColoredBox(color: Colors.blueGrey, child: Text('fake preview')),
  );
}

class FakePermissionService implements CameraPermissionService {
  @override
  Future<CameraPermission> status() async => CameraPermission.granted;

  @override
  Future<CameraPermission> request() async => CameraPermission.granted;

  @override
  Future<void> openSettings() async {}
}

class FakeConnectivityService implements ConnectivityService {
  bool online = true;
  final _changes = StreamController<bool>.broadcast();

  void setOnline(bool value) {
    online = value;
    _changes.add(value);
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onlineChanges => _changes.stream;
}

/// Workmanager cannot be driven from a test, so scheduling is only recorded;
/// the test runs the queue itself, as the worker would.
class RecordingSyncScheduler implements SyncScheduler {
  final List<bool> requests = [];

  @override
  Future<void> requestSync({bool immediate = false}) async =>
      requests.add(immediate);
}

class InMemoryModeStore implements MockUploadModeStore {
  MockUploadMode mode = MockUploadMode.failure;

  @override
  Future<MockUploadMode> read() async => mode;

  @override
  Future<void> write(MockUploadMode mode) async => this.mode = mode;
}

class InMemoryPauseStore implements SyncPauseStore {
  bool paused = false;

  @override
  Future<bool> isPaused() async => paused;

  @override
  Future<void> write(bool paused) async => this.paused = paused;
}
