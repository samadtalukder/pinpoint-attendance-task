# Task 1: Android Attendance

Stack: Kotlin, Jetpack Compose (Material 3), Hilt, StateFlow, DataStore, Fused Location, osmdroid.

## Build and test
- JDK 17. Set `ANDROID_HOME` (never create or edit `local.properties`).
- `./gradlew lintDebug testDebugUnitTest`
- `./gradlew connectedDebugAndroidTest` (emulator `Pixel_9_Pro_XL`)
- `./gradlew assembleRelease`

## Rules
- Package root `com.intelmachin.attendance`: `domain/` (pure Kotlin + `java.time`, no Android imports), `data/`, `di/`, `ui/`.
- Business rules (distance, eligibility, window) live in use cases; ViewModel only orchestrates.
- Constants in `domain/AttendanceRules.kt`: radius 50 m, accuracy limit, window 09:00-10:30.
- Inject `Clock` and location providers so tests stay deterministic.
- Compose version pins: compileSdk 36 caps Compose BOM at 2025.10.x with AGP 8.13.
