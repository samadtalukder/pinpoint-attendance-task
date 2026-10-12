# Intelmachin Task Assessment

A field-ops toolkit with two apps in one repo:

- **task-1-android-attendance**: geo-fenced attendance (native Android, Kotlin + Jetpack Compose)
- **task-2-flutter-camera-sync**: custom camera with an offline-first upload queue (Flutter)

> TODO: one or two sentences on what each app does and why.

## Project Structure and Approach

### task-1-android-attendance
- Architecture: MVVM with a layered structure (data, domain, ui).
- Main classes: `AttendanceViewModel` (exposes `StateFlow<AttendanceUiState>`), `LocationRepository`, `DistanceCalculator`.
- Storage: DataStore for the saved office location.

> TODO: finish after implementation.

### task-2-flutter-camera-sync
- Architecture: layered (data, domain, presentation) with Cubit for state.
- Main classes: `CameraCubit`, `UploadQueueCubit`, `UploadRepository`, `MockUploadApi`.
- Background sync: workmanager worker with a connectivity constraint and backoff.
- Storage: local database for the pending queue.

> TODO: finish after implementation.

## Assumptions
1. The 09:00 to 10:30 attendance window is enforced; it is defined as constants.
2. The 0.5x button only appears on devices that have an ultrawide camera.
3. Office location can be re-set at any time.
4. No real API was provided, so uploads go through `MockUploadApi` with a success/failure toggle.

## Generative AI Usage
I used Claude Code for scaffolding, boilerplate and review, and wrote or checked the core logic myself.

> TODO: copy the essential prompts from `PROMPTS.md` and say what each produced.

## How to Run

### task-1-android-attendance
```bash
git clone <repo-url>
cd <repo>/task-1-android-attendance
./gradlew installDebug
```
Requires Android Studio, an Android device or emulator with location services.

### task-2-flutter-camera-sync
```bash
cd <repo>/task-2-flutter-camera-sync
flutter pub get
flutter run
```
Test on a physical device for camera zoom and background sync.

## Screenshots
> TODO: add images from `screenshots/`.

## Release APKs
> TODO: add the Drive link.
