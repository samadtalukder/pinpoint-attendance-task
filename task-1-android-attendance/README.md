# Pinpoint Attendance (Task 1)

Geo-fenced attendance screen for native Android. Save the office location once, then check in only when you are
within 50 m of it, with an acceptable GPS fix, inside the 09:00-10:30 window.

Kotlin, Jetpack Compose, MVVM, `StateFlow`, DataStore. Back to the [repository overview](../README.md).
Download APK: [pinpoint-attendance-v1.0.apk](../download-apk/pinpoint-attendance-v1.0.apk).

## Requirements coverage
| Requirement | Where it lives |
|---|---|
| `AttendanceScreen` follows the mockup (office card, distance ring, IN RANGE / OUT OF RANGE chip, locked card) | `ui/attendance/AttendanceScreen`, `AttendanceContent`, `components/` |
| "Set Office Location" saves the current GPS fix locally, can be re-set | `SetOfficeLocationUseCase`, DataStore office repository |
| Mark Attendance only within 50 m | `AttendanceRules.OFFICE_RADIUS_METERS`, `CalculateDistanceUseCase`, `EvaluateAttendanceUseCase` |
| GPS accuracy acceptable | `AttendanceRules.MAX_ACCURACY_METERS` (30 m), `MAX_FIX_AGE_MILLIS` (15 s) |
| Time window 09:00-10:30 | `AttendanceRules.WINDOW_START` / `WINDOW_END`, injected `java.time.Clock` |
| Live distance text | "You are 120m away from the office", ring updates about every 2 s |
| Permission denied, permanently denied, GPS off, no fix yet | Distinct UI states in `StatusBanner`, each with an action |

## Technology stack
| | |
|---|---|
| Language | Kotlin 2.2.21, JVM 17 |
| Platform | Android, `minSdk` 26, `compileSdk`/`targetSdk` 36 (AGP 8.13.2) |
| Architecture | Layered MVVM: `ui` -> `domain` -> `data`, one immutable `AttendanceUiState` |
| Patterns | Repository, Adapter/Wrapper, Use case, Observer, Constructor injection |
| UI | Jetpack Compose (BOM 2025.10.01), Material 3, `osmdroid` 6.1.20 for the office map |
| State | `ViewModel` + `StateFlow`, Lifecycle 2.9.4, Coroutines 1.10.2 |
| DI | Hilt 2.57.2 (KSP) |
| Storage | Jetpack DataStore Preferences 1.2.1 (office location, check-in day) |
| Location | Google Play Services Location 21.3.0 (`FusedLocationProviderClient`) behind `LocationRepository` |
| Tests | JUnit 4.13.2, coroutines-test, Turbine 1.2.1, Robolectric 4.16, Compose UI test, Espresso 3.7.0, Hilt testing |

Why these choices: Compose and `StateFlow` give one-way data flow with a single state object; Hilt gives compile-time
checked constructor injection; DataStore replaces `SharedPreferences` with a coroutine-safe store; Robolectric runs the
Compose UI tests on the JVM with the unit tests.

## Project structure
```
task-1-android-attendance/
├── build.gradle.kts, settings.gradle.kts
├── gradle/libs.versions.toml       version catalog for every dependency
├── screenshots/                    images used by this README
└── app/src/
    ├── main/java/com/intelmachin/attendance/
    │   ├── AttendanceApp.kt        Hilt application class
    │   ├── MainActivity.kt         single activity, hosts AttendanceScreen
    │   ├── di/                     Hilt module: binds interfaces to implementations
    │   ├── ui/
    │   │   ├── attendance/         AttendanceScreen, AttendanceContent, AttendanceViewModel,
    │   │   │                       AttendanceUiState, AttendanceTexts
    │   │   │   └── components/     DistanceRing, RangeChip, OfficeContextCard,
    │   │   │                       MarkAttendanceCard, StatusBanner, OfficeMap
    │   │   └── theme/              Material 3 theme and status colors
    │   ├── domain/
    │   │   ├── AttendanceRules.kt  constants: 50 m, 30 m accuracy, 09:00-10:30
    │   │   ├── AttendancePolicy.kt
    │   │   ├── model/              plain data classes
    │   │   ├── repository/         Location, Office and CheckIn repository interfaces
    │   │   └── usecase/            CalculateDistance, EvaluateAttendance,
    │   │                           SetOfficeLocation, MarkAttendance
    │   └── data/
    │       ├── location/           FusedLocationRepository (Play Services)
    │       └── store/              DataStore office and check-in repositories
    ├── test/                       JUnit, Turbine and Robolectric Compose tests, with fakes
    └── androidTest/                Hilt end-to-end flow test on an emulator
```

| Folder | Layer | Responsibility |
|---|---|---|
| `ui/` | presentation | Renders `AttendanceUiState`; the ViewModel combines the flows. No business rules. |
| `domain/` | domain | Rules, use cases and repository interfaces. No Android imports. |
| `data/` | data | Implements the domain interfaces with Play Services and DataStore. |
| `di/` | wiring | Hilt module; the only place that knows both domain and data. |

## Approach
Layered **MVVM**: `ui` -> `domain` -> `data`, dependencies point inward, wired with Hilt constructor injection.
`AttendanceViewModel` combines the location, office and check-in flows (plus a 5 s clock tick) into one
immutable `AttendanceUiState`; the composables only render it.

```
ui/attendance   AttendanceScreen (Android plumbing), AttendanceContent (stateless), components, AttendanceViewModel
domain          AttendanceRules (50 m, 30 m accuracy, 09:00-10:30), use cases, repository interfaces
data            FusedLocationRepository, DataStore office and check-in repositories
```

Patterns, used where they earn their place:
- **Repository**: `LocationRepository`, `OfficeRepository`, `CheckInRepository` are interfaces in domain; the fused
  location and DataStore classes are the implementations.
- **Adapter/Wrapper**: Play Services location and DataStore sit behind those interfaces, so tests use fakes.
- **Use case**: one class per rule: `CalculateDistanceUseCase` (haversine), `EvaluateAttendanceUseCase`,
  `SetOfficeLocationUseCase`, `MarkAttendanceUseCase`.
- **Observer**: Kotlin `Flow`/`StateFlow` end to end.
- **Constructor injection** with Hilt. `java.time.Clock` is injected, so time rules are deterministic in tests.

How the rules work:
- **Set Office Location** takes a fresh GPS fix (accuracy must be 30 m or better) and saves it with DataStore.
  It can be re-set at any time. The office is the phone's position when the button is tapped.
- **Mark Attendance** unlocks only when all of these hold: distance <= 50 m (haversine), accuracy <= 30 m, the fix
  is no older than 15 s, the time is inside 09:00-10:30, and you have not checked in today. It re-checks with a new fix
  at tap time, so a stale reading cannot pass.
- **Live distance** updates about every 2 s ("You are 120m away from the office", plus the ring).
- **Failure states, each with an action:** permission denied (Grant permission), permanently denied (Open settings),
  GPS off (Enable GPS), waiting for a fix (progress), signal lost (warning and locked).

## Testing
JUnit, Turbine, Robolectric Compose tests in `app/src/test`: distance, range rules, time window, ViewModel, DataStore, locked vs unlocked card, permission states (unit and Compose UI, run on the JVM).
End to end: Hilt flow test in `app/src/androidTest` (set office, move in range, mark attendance).
Tests are deterministic: clock, location and repositories are injected fakes.

```bash
./gradlew lintDebug testDebugUnitTest
./gradlew connectedDebugAndroidTest      # emulator or device
```

## How to run
```bash
git clone https://github.com/samadtalukder/pinpoint-attendance-task.git
cd pinpoint-attendance-task/task-1-android-attendance
./gradlew installDebug
```
Requires JDK 17 and Android Studio (or the Android SDK with `ANDROID_HOME` set), plus a device or emulator with
location services. Open the app, allow location, tap **Set Office Location**, then move.
On an emulator, set the position with `adb emu geo fix <longitude> <latitude>`.

Release build (signed with your `key.properties` if present, otherwise with the local debug key):
```bash
./gradlew assembleRelease   # app/build/outputs/apk/release/app-release.apk
```

### Reviewer guide: trigger each state
| To see | Do this |
|---|---|
| Out of range | Set the office, then move more than 50 m. |
| Time window | Mark Attendance is locked outside 09:00-10:30 and the card shows the window. Set the device clock inside the window to unlock it. |
| Permission denied / permanently denied | Deny location once, then deny again with "Don't ask again". The banner offers **Grant permission** or **Open settings**. |
| GPS off | Turn location off in quick settings. The banner offers **Enable GPS**. |

## Screenshots
| Setup | Out of range | In range | Checked in |
|---|---|---|---|
| ![Setup](screenshots/01-setup-no-office.png) | ![Out of range](screenshots/02-out-of-range.png) | ![In range](screenshots/03-in-range-unlocked.png) | ![Checked in](screenshots/04-checked-in.png) |

| Permission denied | GPS off |
|---|---|
| ![Permission denied](screenshots/05-permission-denied.png) | ![GPS off](screenshots/06-gps-off.png) |

Demo (set office, move out of range, move within 50 m, mark attendance):

![Pinpoint Attendance demo](../Demo/task-1-attendance.gif)
