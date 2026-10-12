# Intelmachin Task Assessment

Senior App Developer assessment for Intelligent Machines Limited. One repo, two apps. Deadline: Wed 14 Oct 2026. Read `assessment-brief.pdf` (local copy of the brief, gitignored) before changing anything.

## Layout
- `task-1-android-attendance/`: Task 1. Native Android, Kotlin, Jetpack Compose, MVVM, StateFlow, DataStore. No Flutter code here.
- `task-2-flutter-camera-sync/`: Task 2. Flutter, Cubit (flutter_bloc), layered architecture, workmanager, local DB (Drift or sqflite).
- `<task folder>/screenshots/`: images and GIFs for that task, used by the README.
- Each app has its own `CLAUDE.md` with stack-specific rules. Read it when working there.


## Task 1 rules (Attendance)
- Screen is `AttendanceScreen`, UI must follow the mockup: office context card, distance ring, IN RANGE / OUT OF RANGE chip, locked "Mark Attendance" card.
- "Set Office Location" fetches current GPS and saves it locally. Re-settable at any time.
- Mark Attendance is enabled only if distance <= 50 m, GPS accuracy is acceptable, and time is inside the window (09:00-10:30, defined as constants).
- Live distance text, e.g. "You are 120m away from the office".
- Handle: permission denied, permanently denied, GPS off, no fix yet. Each needs a visible UI state.


## Task 2 rules (Camera and Sync)
- Screens: `CameraPreviewScreen`, Upload Manager (Pending Uploads list).
- Zoom: pinch, slider, rounded 0.5x / 1x / 2x buttons. Show 0.5x only if the device has an ultrawide lens.
- Tap-to-focus with a visible indicator at the tap point.
- Capture multiple batches. Queue persists locally. Images stay in the queue on failure.
- Workmanager worker monitors connectivity and retries automatically with backoff, no user action.
- No real API exists. Use `MockUploadApi` with a toggleable success/failure.

## Working style
- Use plan mode for anything with 3+ steps or an architecture decision. If something goes sideways, stop and re-plan.
- Fix root causes, no temporary fixes. Touch only what's necessary.
- Never call a task done without proof: run tests and lint, and exercise the feature.
- Challenge your own work before presenting it, but don't over-engineer simple things.

## Architecture and design patterns
- Layered: presentation -> domain -> data. Dependencies point inward; domain has no framework imports.
- Use patterns only where they earn their place, and name them in the README:
  - **Repository**: interface in domain, implementation in data (location, office storage, upload queue).
  - **Adapter/Wrapper**: platform plugins (location, camera, connectivity, workmanager) sit behind our own interfaces so they can be faked in tests.
  - **Use case**: one small class per business rule (e.g. validate range, enqueue batch, retry uploads). Skip it if it would only forward a call.
  - **Observer**: StateFlow (Android) and Cubit streams (Flutter) for UI state.
  - **Constructor injection** for dependencies. No service locators sprinkled through widgets or composables.
- One immutable UI state object per screen. UI renders state, never computes business rules.

## SOLID
- **S**: one reason to change per class. A ViewModel/Cubit orchestrates; it does not do math, storage and I/O itself.
- **O**: extend behavior by adding implementations (e.g. a real upload API behind the same interface), not by editing consumers.
- **L**: fakes and real implementations must be interchangeable behind an interface.
- **I**: small interfaces (`LocationProvider`, `OfficeStore`, `UploadApi`), not one big service.
- **D**: depend on abstractions defined in domain; implementations are wired at the app root.
- DRY, KISS, YAGNI. No unused dependencies, no dead code.

## UI/UX guidelines
- Material 3. Follow the supplied mockups closely (layout, hierarchy, states, copy).
- Every screen handles loading, empty, success and error states explicitly. Never show a blank screen.
- Permission and hardware errors explain what happened and offer the next action (e.g. "Open settings", "Enable GPS").
- Touch targets at least 48dp. Contrast at least WCAG AA. Respect system font scaling and dark mode where the design allows.
- Accessibility: content descriptions or semantic labels on icons, buttons and the distance ring; state is not conveyed by color alone (text plus icon).
- No hardcoded user-facing strings or magic numbers. Use string resources and named constants (50 m radius, time window, retry backoff).
- Immediate feedback for actions (progress, disabled states with a reason, confirmation after marking attendance or capturing).
- Keep animations subtle and never block interaction.

## Testing
Write tests alongside each feature, not at the end. Priority order if time runs short: unit, then widget/UI, then integration.
- **Unit**: pure logic and state holders. Distance and range validation, time window, ViewModel/Cubit transitions, retry/backoff rules, queue repository with fakes. Cover failure paths, not just the happy path.
- **Widget / Compose UI**: key screens rendered with fake state. Verify locked vs unlocked "Mark Attendance", distance text, permission-denied UI, zoom controls, pending uploads list.
- **Integration**: one end-to-end flow per app on a device or emulator, with fakes for GPS, camera and network (set office -> move in range -> mark attendance; capture batch -> upload fails -> queue persists -> upload succeeds).
- Tests must be deterministic: inject clocks, fake locations and fake connectivity. No real network, no sleeping.
- A feature is not done until its tests pass.

## Definition of Done (per task)
- Layers respected, dependencies point inward, no duplicated logic.
- Unit and widget/UI tests for the feature pass. Integration test updated if the main flow changed.
- Flutter: `flutter analyze` clean, `flutter test` passes.
- Android: `./gradlew lintDebug testDebugUnitTest` passes.
- Edge cases handled: permission denied, GPS off, no camera, offline, mid-upload failure.
- Release build succeeds for both apps before submission.
- If an earlier task missed any of this, fix it before starting the next.

## Engineering rules
- Never edit signing files (`*.jks`, `key.properties`, `local.properties`).
- Handle permission and hardware failures gracefully, never crash.
- Do not run `git push`. I push manually.


## Git
- Work on `develop` with small commits, one feature per commit: `feat: ...`, `fix: ...`, `test: ...`, `chore: ...`.
- Screens use the `Screen` suffix (`AttendanceScreen`, `CameraPreviewScreen`).
- Commit message format: `feat: add slot hold endpoint` / `fix: redis key expiry`
- Do NOT add `Co-Authored-By` or any other trailer to commits

## Assumptions (also documented in README)
1. Time window 09:00-10:30 is enforced via constants.
2. 0.5x button appears only on devices with an ultrawide camera.
3. Office location can be re-set at any time.

## Prompt log
A hook appends every prompt to `PROMPTS.raw.md` (gitignored). At the end I pick the essential ones into `PROMPTS.md`.