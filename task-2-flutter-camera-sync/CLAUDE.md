# Flutter app (Task 2: Camera and Sync)

Flutter, flutter_bloc (Cubit), layered architecture, workmanager, local DB (Drift or sqflite, pick one).

## Structure
```
lib/
  core/            constants, connectivity wrapper, DI wiring, theme
  data/            local DB + DAOs, MockUploadApi, repository impls
  domain/          entities (CaptureBatch, PendingUpload), repository interfaces, use cases
  workers/         workmanager callbackDispatcher and sync task
  presentation/    camera/, upload_manager/ (screens, cubits, widgets)
test/              unit and widget tests
integration_test/  end-to-end flow
```

## Rules
- State: Cubits (`CameraCubit`, `UploadQueueCubit`) with immutable state classes. Use Equatable; avoid code generation (no freezed/injectable/build_runner) to keep the build simple.
- DI: constructor injection, wired in one place (get_it is fine, registered by hand).
- Wrap plugins behind our interfaces: `CameraService` (zoom, focus, capture, available lenses), `ConnectivityService`, `UploadApi`. Screens and Cubits depend on the interfaces only.
- `MockUploadApi` has a success/failure toggle and simulated latency; real API calls stay commented out with a clear note.
- Workmanager: a connectivity-constrained task with exponential backoff. The worker reads the pending queue from the DB, uploads, removes on success, and leaves items on failure. It must work after the app is closed.
- 0.5x button only if an ultrawide lens is reported.
- Dispose camera controllers and cancel stream subscriptions.
- Screens use the `Screen` suffix. No hardcoded strings or magic numbers; use constants.

## Tests
- Unit (`test/`): `bloc_test` + `mocktail`. Cover Cubit transitions, queue repository (persist, retry, remove on success, keep on failure), backoff rules, batch creation.
- Widget (`test/`): pump `CameraPreviewScreen` and Upload Manager with fake services. Verify zoom buttons and slider, focus indicator appears on tap, pending list and statuses render, empty state.
- Integration (`integration_test/`): capture a batch with fake camera, upload fails (mock), item stays queued, flip to success, queue drains.
- Deterministic: fake connectivity and clock, no real camera or network in tests.

## Commands
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter test integration_test` (needs a device or emulator)
- `flutter build apk --release` (universal APK, signed via `android/key.properties`, which is gitignored)
