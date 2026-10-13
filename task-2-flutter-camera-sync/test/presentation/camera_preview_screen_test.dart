import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinpoint_capture/core/camera_preview_source.dart';
import 'package:pinpoint_capture/core/strings.dart';
import 'package:pinpoint_capture/domain/entities/capture_batch.dart';
import 'package:pinpoint_capture/domain/entities/captured_image.dart';
import 'package:pinpoint_capture/domain/entities/zoom_capabilities.dart';
import 'package:pinpoint_capture/domain/services/camera_permission_service.dart';
import 'package:pinpoint_capture/domain/services/camera_service.dart';
import 'package:pinpoint_capture/domain/usecases/enqueue_batch_use_case.dart';
import 'package:pinpoint_capture/presentation/camera/camera_cubit.dart';
import 'package:pinpoint_capture/presentation/camera/camera_preview_screen.dart';
import 'package:pinpoint_capture/presentation/camera/widgets/focus_indicator.dart';

class MockCamera extends Mock implements CameraService {}

class MockPermission extends Mock implements CameraPermissionService {}

class MockEnqueue extends Mock implements EnqueueBatchUseCase {}

class FakePreview implements CameraPreviewSource {
  @override
  Widget buildPreview() => const SizedBox.expand(
    key: Key('preview'),
    child: ColoredBox(color: Colors.teal),
  );
}

void main() {
  const photo = CapturedImage(path: '/none/a.jpg', name: 'a.jpg', sizeBytes: 5);

  late MockCamera camera;
  late MockPermission permission;
  late MockEnqueue enqueue;
  var capabilities = const ZoomCapabilities(min: 0.5, max: 8);

  setUpAll(() {
    registerFallbackValue(<CapturedImage>[]);
    registerFallbackValue(CameraLens.back);
  });

  setUp(() {
    capabilities = const ZoomCapabilities(min: 0.5, max: 8);
    camera = MockCamera();
    permission = MockPermission();
    enqueue = MockEnqueue();
    when(() => permission.status())
        .thenAnswer((_) async => CameraPermission.granted);
    when(() => permission.openSettings()).thenAnswer((_) async {});
    when(() => camera.initialize(lens: any(named: 'lens')))
        .thenAnswer((_) async => capabilities);
    when(() => camera.setZoom(any())).thenAnswer((_) async {});
    when(() => camera.focusAt(any(), any())).thenAnswer((_) async {});
    when(() => camera.capture()).thenAnswer((_) async => photo);
    when(() => camera.dispose()).thenAnswer((_) async {});
    when(() => camera.setFlash(any())).thenAnswer((_) async {});
    when(() => camera.canFlip).thenReturn(true);
  });

  Future<CameraCubit> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = CameraCubit(camera, permission, enqueue);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: CameraPreviewScreen(
            previewSource: FakePreview(),
            onOpenUploads: () {},
          ),
        ),
      ),
    );
    await cubit.initialize();
    await tester.pump();
    return cubit;
  }

  testWidgets('shows 0.5x, 1x and 2x when the device has an ultrawide lens', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('0.5x'), findsOneWidget);
    expect(find.text('1x'), findsOneWidget);
    expect(find.text('2x'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('hides 0.5x without an ultrawide lens', (tester) async {
    capabilities = const ZoomCapabilities(min: 1, max: 8);

    await pumpScreen(tester);

    expect(find.text('0.5x'), findsNothing);
    expect(find.text('1x'), findsOneWidget);
    expect(find.text('2x'), findsOneWidget);
  });

  testWidgets('tapping a preset zooms the camera', (tester) async {
    final cubit = await pumpScreen(tester);

    await tester.tap(find.text('2x'));
    await tester.pump();

    verify(() => camera.setZoom(2)).called(1);
    expect(cubit.state.zoom, 2);
  });

  testWidgets('dragging the slider changes the zoom', (tester) async {
    final cubit = await pumpScreen(tester);
    final before = cubit.state.zoom;

    // The slider is rotated: dragging up raises the value.
    await tester.drag(find.byType(Slider), const Offset(0, -60));
    await tester.pump();

    expect(cubit.state.zoom, greaterThan(before));
    verify(() => camera.setZoom(any())).called(greaterThan(0));
  });

  testWidgets('pinching out zooms in', (tester) async {
    final cubit = await pumpScreen(tester);
    final center = tester.getCenter(find.byKey(const Key('preview')));

    final a = await tester.startGesture(center - const Offset(20, 0));
    final b = await tester.startGesture(center + const Offset(20, 0));
    await a.moveBy(const Offset(-40, 0));
    await b.moveBy(const Offset(40, 0));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pump();

    expect(cubit.state.zoom, greaterThan(1));
  });

  testWidgets('tap on the preview shows a focus indicator and focuses', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.byType(FocusIndicator), findsNothing);

    final rect = tester.getRect(find.byKey(const Key('preview')));
    final tapAt = rect.topLeft + Offset(rect.width * 0.25, rect.height * 0.5);
    await tester.tapAt(tapAt);
    await tester.pump();

    expect(find.byKey(const Key('focus_indicator')), findsOneWidget);
    final indicator = tester.getCenter(
      find.byKey(const Key('focus_indicator')),
    );
    expect((indicator - tapAt).distance, lessThan(1));
    final captured = verify(() => camera.focusAt(captureAny(), captureAny()))
        .captured;
    expect(captured[0], closeTo(0.25, 0.01));
    expect(captured[1], closeTo(0.5, 0.01));

    await tester.pump(FocusIndicator.duration);
  });

  testWidgets('shutter adds to the batch and enables upload', (tester) async {
    await pumpScreen(tester);
    expect(find.text(AppStrings.uploadBatchEmpty), findsOneWidget);

    await tester.tap(find.byKey(const Key('shutter')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('shutter')));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    expect(find.text(AppStrings.uploadBatch(2)), findsOneWidget);
  });

  testWidgets('upload batch queues the photos and confirms', (tester) async {
    final cubit = await pumpScreen(tester);
    when(
      () => enqueue(any()),
    ).thenAnswer((_) async => CaptureBatch(id: 1, createdAt: DateTime(2026)));
    await tester.tap(find.byKey(const Key('shutter')));
    await tester.pump();

    await tester.tap(find.text(AppStrings.uploadBatch(1)));
    await tester.pump();
    await tester.pump();

    verify(() => enqueue([photo])).called(1);
    expect(cubit.state.batch, isEmpty);
    expect(find.text(AppStrings.batchQueued(1)), findsOneWidget);
    expect(find.text(AppStrings.uploadBatchEmpty), findsOneWidget);
  });

  testWidgets('queue failure keeps the photos and says so', (tester) async {
    await pumpScreen(tester);
    when(() => enqueue(any())).thenThrow(StateError('disk'));
    await tester.tap(find.byKey(const Key('shutter')));
    await tester.pump();

    await tester.tap(find.text(AppStrings.uploadBatch(1)));
    await tester.pump();
    await tester.pump();

    expect(find.text(AppStrings.queueFailed), findsOneWidget);
    expect(find.text(AppStrings.uploadBatch(1)), findsOneWidget);
  });

  testWidgets('denied permission offers to ask again', (tester) async {
    when(() => permission.status())
        .thenAnswer((_) async => CameraPermission.denied);
    when(() => permission.request())
        .thenAnswer((_) async => CameraPermission.denied);
    await pumpScreen(tester);

    expect(find.text(AppStrings.permissionDeniedTitle), findsOneWidget);
    expect(find.byKey(const Key('preview')), findsNothing);

    when(() => permission.request())
        .thenAnswer((_) async => CameraPermission.granted);
    await tester.tap(find.text(AppStrings.grantPermission));
    await tester.pump();
    await tester.pump();

    expect(find.text('1x'), findsOneWidget);
  });

  testWidgets('permanently denied permission offers Open settings', (
    tester,
  ) async {
    when(() => permission.status())
        .thenAnswer((_) async => CameraPermission.permanentlyDenied);
    await pumpScreen(tester);

    await tester.tap(find.text(AppStrings.openSettings));

    verify(() => permission.openSettings()).called(1);
  });

  testWidgets('no camera is explained', (tester) async {
    when(() => camera.initialize(lens: any(named: 'lens')))
        .thenThrow(const CameraFailure(CameraFailureType.noCamera));
    await pumpScreen(tester);

    expect(find.text(AppStrings.noCameraTitle), findsOneWidget);
  });

  testWidgets('camera error offers Try again', (tester) async {
    when(() => camera.initialize(lens: any(named: 'lens')))
        .thenThrow(const CameraFailure(CameraFailureType.unavailable));
    await pumpScreen(tester);
    expect(find.text(AppStrings.cameraErrorTitle), findsOneWidget);

    when(() => camera.initialize(lens: any(named: 'lens')))
        .thenAnswer((_) async => capabilities);
    await tester.tap(find.text(AppStrings.tryAgain));
    await tester.pump();
    await tester.pump();

    expect(find.text('1x'), findsOneWidget);
  });

  testWidgets('backgrounding releases the camera and resuming restarts it', (
    tester,
  ) async {
    await pumpScreen(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    verify(() => camera.dispose()).called(1);
    expect(find.byKey(const Key('preview')), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    verify(() => camera.initialize(lens: any(named: 'lens'))).called(2);
    expect(find.byKey(const Key('preview')), findsOneWidget);
  });
}
