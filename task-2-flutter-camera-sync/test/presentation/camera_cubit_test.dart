import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinpoint_capture/domain/entities/capture_batch.dart';
import 'package:pinpoint_capture/domain/entities/captured_image.dart';
import 'package:pinpoint_capture/domain/entities/zoom_capabilities.dart';
import 'package:pinpoint_capture/domain/services/camera_permission_service.dart';
import 'package:pinpoint_capture/domain/services/camera_service.dart';
import 'package:pinpoint_capture/domain/usecases/enqueue_batch_use_case.dart';
import 'package:pinpoint_capture/presentation/camera/camera_cubit.dart';
import 'package:pinpoint_capture/presentation/camera/camera_state.dart';

class MockCamera extends Mock implements CameraService {}

class MockPermission extends Mock implements CameraPermissionService {}

class MockEnqueue extends Mock implements EnqueueBatchUseCase {}

void main() {
  const caps = ZoomCapabilities(min: 0.5, max: 8);
  const photo = CapturedImage(path: '/c/a.jpg', name: 'a.jpg', sizeBytes: 5);

  late MockCamera camera;
  late MockPermission permission;
  late MockEnqueue enqueue;

  setUpAll(() {
    registerFallbackValue(<CapturedImage>[]);
    registerFallbackValue(CameraLens.back);
  });

  setUp(() {
    camera = MockCamera();
    permission = MockPermission();
    enqueue = MockEnqueue();
    when(() => permission.status())
        .thenAnswer((_) async => CameraPermission.granted);
    when(() => camera.initialize(lens: any(named: 'lens')))
        .thenAnswer((_) async => caps);
    when(() => camera.setZoom(any())).thenAnswer((_) async {});
    when(() => camera.focusAt(any(), any())).thenAnswer((_) async {});
    when(() => camera.capture()).thenAnswer((_) async => photo);
    when(() => camera.dispose()).thenAnswer((_) async {});
    when(() => camera.setFlash(any())).thenAnswer((_) async {});
    when(() => camera.canFlip).thenReturn(true);
    when(() => permission.openSettings()).thenAnswer((_) async {});
  });

  CameraCubit build() => CameraCubit(camera, permission, enqueue);

  Future<CameraCubit> ready() async {
    final cubit = build();
    await cubit.initialize();
    addTearDown(cubit.close);
    return cubit;
  }

  group('initialize', () {
    blocTest<CameraCubit, CameraState>(
      'granted permission starts the camera at 1x',
      build: build,
      act: (c) => c.initialize(),
      expect: () => [
        const CameraState(),
        const CameraState(
          status: CameraStatus.ready,
          capabilities: caps,
          canFlip: true,
        ),
      ],
    );

    blocTest<CameraCubit, CameraState>(
      'denied permission asks once and reports denial',
      setUp: () {
        when(() => permission.status())
            .thenAnswer((_) async => CameraPermission.denied);
        when(() => permission.request())
            .thenAnswer((_) async => CameraPermission.denied);
      },
      build: build,
      act: (c) => c.initialize(),
      verify: (c) {
        expect(c.state.status, CameraStatus.permissionDenied);
        verify(() => permission.request()).called(1);
        verifyNever(() => camera.initialize(lens: any(named: 'lens')));
      },
    );

    blocTest<CameraCubit, CameraState>(
      'permanently denied skips the prompt',
      setUp: () =>
          when(() => permission.status())
              .thenAnswer((_) async => CameraPermission.permanentlyDenied),
      build: build,
      act: (c) => c.initialize(),
      verify: (c) {
        expect(c.state.status, CameraStatus.permissionPermanentlyDenied);
        verifyNever(() => permission.request());
      },
    );

    blocTest<CameraCubit, CameraState>(
      'no back camera is reported',
      setUp: () =>
          when(() => camera.initialize(lens: any(named: 'lens')))
              .thenThrow(const CameraFailure(CameraFailureType.noCamera)),
      build: build,
      act: (c) => c.initialize(),
      verify: (c) => expect(c.state.status, CameraStatus.noCamera),
    );

    blocTest<CameraCubit, CameraState>(
      'camera error is reported, not thrown',
      setUp: () =>
          when(() => camera.initialize(lens: any(named: 'lens')))
              .thenThrow(const CameraFailure(CameraFailureType.unavailable)),
      build: build,
      act: (c) => c.initialize(),
      verify: (c) => expect(c.state.status, CameraStatus.error),
    );
  });

  group('zoom', () {
    test('setZoom clamps to the camera range and forwards it', () async {
      final cubit = await ready();

      await cubit.setZoom(20);

      expect(cubit.state.zoom, 8);
      verify(() => camera.setZoom(8)).called(1);
    });

    test('pinch scales from the zoom at gesture start', () async {
      final cubit = await ready();
      await cubit.setZoom(2);

      cubit.pinchStarted();
      await cubit.pinchUpdated(1.5);

      expect(cubit.state.zoom, 3);
    });

    test('ignored before the camera is ready', () async {
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.setZoom(2);

      verifyNever(() => camera.setZoom(any()));
    });

    test(
      'while a zoom is in flight only the latest value is applied',
      () async {
        final cubit = await ready();
        final gate = Completer<void>();
        when(() => camera.setZoom(2)).thenAnswer((_) => gate.future);

        final first = cubit.setZoom(2);
        await cubit.setZoom(3);
        await cubit.setZoom(4);
        gate.complete();
        await first;

        verifyInOrder([() => camera.setZoom(2), () => camera.setZoom(4)]);
        verifyNever(() => camera.setZoom(3));
      },
    );
  });

  group('focus', () {
    test('tap stores the target and focuses the camera', () async {
      final cubit = await ready();

      await cubit.focusAt(const Offset(0.25, 0.75));

      expect(cubit.state.focus!.position, const Offset(0.25, 0.75));
      verify(() => camera.focusAt(0.25, 0.75)).called(1);
    });

    test('each tap gets a new id so the indicator replays', () async {
      final cubit = await ready();

      await cubit.focusAt(const Offset(0.5, 0.5));
      final first = cubit.state.focus!.id;
      await cubit.focusAt(const Offset(0.5, 0.5));

      expect(cubit.state.focus!.id, isNot(first));
    });
  });

  test('a camera released while it was starting is not left open', () async {
    final gate = Completer<ZoomCapabilities>();
    when(() => camera.initialize(lens: any(named: 'lens')))
        .thenAnswer((_) => gate.future);
    final cubit = build();
    addTearDown(cubit.close);

    final starting = cubit.initialize();
    await Future<void>.delayed(Duration.zero);
    await cubit.onAppPaused();
    gate.complete(caps);
    await starting;

    verify(() => camera.dispose()).called(1);
    expect(cubit.state.status, CameraStatus.initializing);

    when(() => camera.initialize(lens: any(named: 'lens')))
        .thenAnswer((_) async => caps);
    await cubit.onAppResumed();
    expect(cubit.state.status, CameraStatus.ready);
  });

  group('capture and queue', () {
    test('capture adds photos to the current batch', () async {
      final cubit = await ready();

      await cubit.capture();
      await cubit.capture();

      expect(cubit.state.batch, [photo, photo]);
      expect(cubit.state.isCapturing, isFalse);
    });

    test('capture failure keeps the batch and reports feedback', () async {
      final cubit = await ready();
      await cubit.capture();
      when(() => camera.capture())
          .thenThrow(const CameraFailure(CameraFailureType.unavailable));

      await cubit.capture();

      expect(cubit.state.batch, [photo]);
      expect(cubit.state.feedback, CameraFeedback.captureFailed);
      expect(cubit.state.isCapturing, isFalse);
    });

    test('an unexpected capture error releases the shutter', () async {
      final cubit = await ready();
      when(() => camera.capture()).thenThrow(StateError('file system'));

      await cubit.capture();

      expect(cubit.state.isCapturing, isFalse);
      expect(cubit.state.feedback, CameraFeedback.captureFailed);
    });

    test('queueBatch enqueues the photos and starts a fresh batch', () async {
      final cubit = await ready();
      await cubit.capture();
      await cubit.capture();
      when(
        () => enqueue(any()),
      ).thenAnswer((_) async => CaptureBatch(id: 1, createdAt: DateTime(2026)));

      await cubit.queueBatch();

      verify(() => enqueue([photo, photo])).called(1);
      expect(cubit.state.batch, isEmpty);
      expect(cubit.state.feedback, CameraFeedback.batchQueued);
      expect(cubit.state.lastQueuedCount, 2);
    });

    test('queueBatch failure keeps the photos for another try', () async {
      final cubit = await ready();
      await cubit.capture();
      when(() => enqueue(any())).thenThrow(StateError('disk full'));

      await cubit.queueBatch();

      expect(cubit.state.batch, [photo]);
      expect(cubit.state.feedback, CameraFeedback.queueFailed);
      expect(cubit.state.isQueueing, isFalse);
    });

    test('queueBatch with an empty batch does nothing', () async {
      final cubit = await ready();

      await cubit.queueBatch();

      verifyNever(() => enqueue(any()));
    });

    test('feedbackShown clears the message', () async {
      final cubit = await ready();
      when(() => camera.capture())
          .thenThrow(const CameraFailure(CameraFailureType.unavailable));
      await cubit.capture();

      cubit.feedbackShown();

      expect(cubit.state.feedback, CameraFeedback.none);
    });
  });

  group('flash and flip', () {
    test('flash toggles and is sent to the camera', () async {
      final cubit = await ready();

      await cubit.toggleFlash();
      expect(cubit.state.flashOn, isTrue);
      verify(() => camera.setFlash(true)).called(1);

      await cubit.toggleFlash();
      expect(cubit.state.flashOn, isFalse);
      verify(() => camera.setFlash(false)).called(1);
    });

    test('flash choice is re-applied when the camera restarts', () async {
      final cubit = await ready();
      await cubit.toggleFlash();
      clearInteractions(camera);

      await cubit.onAppPaused();
      await cubit.onAppResumed();

      verify(() => camera.setFlash(true)).called(1);
    });

    test('canFlip comes from the camera', () async {
      when(() => camera.canFlip).thenReturn(false);

      final cubit = await ready();

      expect(cubit.state.canFlip, isFalse);
    });

    test('flip switches to the front lens and resets zoom', () async {
      final cubit = await ready();
      await cubit.setZoom(4);

      await cubit.flipCamera();

      verify(() => camera.initialize(lens: CameraLens.front)).called(1);
      expect(cubit.state.lens, CameraLens.front);
      expect(cubit.state.status, CameraStatus.ready);
      expect(cubit.state.zoom, 1.0);
    });

    test('flip twice returns to the back lens', () async {
      final cubit = await ready();

      await cubit.flipCamera();
      await cubit.flipCamera();

      expect(cubit.state.lens, CameraLens.back);
    });

    test('flash is not applied on the front lens', () async {
      final cubit = await ready();
      await cubit.toggleFlash();
      clearInteractions(camera);

      await cubit.flipCamera();

      verifyNever(() => camera.setFlash(true));
      expect(cubit.state.flashOn, isTrue, reason: 'choice is remembered');
    });

    test('a failing flip falls back to the previous lens', () async {
      final cubit = await ready();
      when(() => camera.initialize(lens: CameraLens.front))
          .thenThrow(const CameraFailure(CameraFailureType.noCamera));

      await cubit.flipCamera();

      expect(cubit.state.lens, CameraLens.back);
      expect(cubit.state.status, CameraStatus.ready);
      expect(cubit.state.feedback, CameraFeedback.flipFailed);
    });

    test('flip does nothing when the device cannot flip', () async {
      when(() => camera.canFlip).thenReturn(false);
      final cubit = await ready();
      clearInteractions(camera);

      await cubit.flipCamera();

      verifyNever(() => camera.initialize(lens: any(named: 'lens')));
      expect(cubit.state.lens, CameraLens.back);
    });

    test('resume restarts on the lens in use', () async {
      final cubit = await ready();
      await cubit.flipCamera();
      clearInteractions(camera);

      await cubit.onAppPaused();
      await cubit.onAppResumed();

      verify(() => camera.initialize(lens: CameraLens.front)).called(1);
    });
  });

  group('lifecycle', () {
    test('pause releases the camera and resume restarts it', () async {
      final cubit = await ready();

      await cubit.onAppPaused();
      verify(() => camera.dispose()).called(1);

      await cubit.onAppResumed();
      verify(() => camera.initialize(lens: any(named: 'lens'))).called(2);
      expect(cubit.state.status, CameraStatus.ready);
    });

    test('resume without a pause does not restart a running camera', () async {
      final cubit = await ready();

      await cubit.onAppResumed();

      verify(() => camera.initialize(lens: any(named: 'lens'))).called(1);
    });

    test(
      'resume re-checks permission after the user visited settings',
      () async {
        when(() => permission.status())
            .thenAnswer((_) async => CameraPermission.permanentlyDenied);
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.initialize();
        expect(cubit.state.status, CameraStatus.permissionPermanentlyDenied);

        when(() => permission.status())
            .thenAnswer((_) async => CameraPermission.granted);
        await cubit.onAppResumed();

        expect(cubit.state.status, CameraStatus.ready);
      },
    );

    test('resume while denied does not prompt again '
        '(the system dialog itself triggers a resume)', () async {
      when(() => permission.status())
          .thenAnswer((_) async => CameraPermission.denied);
      when(() => permission.request())
          .thenAnswer((_) async => CameraPermission.permanentlyDenied);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.initialize();
      verify(() => permission.request()).called(1);

      await cubit.onAppResumed();
      await cubit.onAppResumed();

      // status() cannot tell "denied" from "blocked" on Android, so resume
      // must not overwrite what request() reported.
      verifyNever(() => permission.request());
      expect(cubit.state.status, CameraStatus.permissionPermanentlyDenied);
    });

    test('close releases the camera', () async {
      final cubit = await ready();

      await cubit.close();

      verify(() => camera.dispose()).called(1);
    });
  });
}
