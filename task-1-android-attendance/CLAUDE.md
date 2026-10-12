# Android app (Task 1: Attendance)

Kotlin, Jetpack Compose, Material 3, MVVM. Package: `com.intelmachin.attendance`.

## Structure
```
data/     DataStore office store, FusedLocation-based LocationRepository impl
domain/   OfficeLocation, DistanceCalculator, ValidateRangeUseCase, AttendanceWindow, repository interfaces
ui/       AttendanceScreen, AttendanceViewModel, AttendanceUiState, theme, components
```

## Rules
- `AttendanceViewModel` exposes one `StateFlow<AttendanceUiState>`; UI collects with `collectAsStateWithLifecycle`.
- Location comes from our `LocationProvider` interface (fused location, high accuracy). Never call the Play Services API from the ViewModel or composables.
- Distance via `Location.distanceTo` or Haversine inside `DistanceCalculator` (pure Kotlin, unit-testable). Ignore fixes with poor accuracy.
- Inject a `Clock`/time provider so the 09:00-10:30 window is testable.
- Dependency injection: Hilt or manual constructor injection, whichever is simpler to set up. No static singletons.
- Composables take state and lambdas; stateless where possible; previews for each UI state.
- Strings in `strings.xml`, constants in a constants file.

## Tests
- Unit (`src/test`): JUnit + coroutines-test + Turbine, fakes for `LocationProvider`, `OfficeStore`, `Clock`. Cover `DistanceCalculator`, range validation (49 m, 50 m, 51 m), time window edges, ViewModel state transitions, permission and GPS-off states.
- Compose UI (`src/androidTest` or Robolectric): `createComposeRule()`, render `AttendanceScreen` with fake state; assert button enabled/disabled, distance text, status chip, permission UI.
- Integration (`src/androidTest`): one flow with fake providers injected: set office, move in range, mark attendance.

## Commands
- `./gradlew testDebugUnitTest`
- `./gradlew lintDebug`
- `./gradlew connectedDebugAndroidTest` (needs a device or emulator)
- `./gradlew assembleRelease` (needs signing config via `key.properties`, which is gitignored)
