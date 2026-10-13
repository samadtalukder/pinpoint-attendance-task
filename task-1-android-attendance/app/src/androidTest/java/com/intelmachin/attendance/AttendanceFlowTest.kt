package com.intelmachin.attendance

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.fakes.FakeLocationRepository
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import javax.inject.Inject

private const val TIMEOUT_MS = 5_000L
/** Window package of the system permission dialog. Its view ids use the AOSP package below. */
private const val PERMISSION_CONTROLLER_PKG = "com.google.android.permissioncontroller"
private const val PERMISSION_UI_RES_PKG = "com.android.permissioncontroller"
private const val ALLOW_FOREGROUND_ID = "permission_allow_foreground_only_button"
private const val ALLOW_ID = "permission_allow_button"

/** Karwan Bazar, Dhaka. */
private val OFFICE = GeoPoint(23.7509, 90.3935)

/** Point roughly [meters] due north of [from] (1 deg latitude is about 111,195 m). */
private fun northOf(from: GeoPoint, meters: Double) = GeoPoint(from.latitude + meters / 111_195.0, from.longitude)

/**
 * End-to-end flow on a device with fake GPS, in-memory storage and a clock fixed inside the window:
 * grant location from the explanation screen via the real system dialog -> set office -> walk away (locked)
 * -> walk back within 50 m -> mark attendance.
 *
 * The permission step runs only while the app does not hold the permission yet (a fresh install, which
 * Gradle's connected run gives you); on a device that already granted it, the flow starts at "set office".
 */
@HiltAndroidTest
class AttendanceFlowTest {

    @get:Rule(order = 0)
    val hilt = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val compose = createAndroidComposeRule<MainActivity>()

    @Inject lateinit var gps: FakeLocationRepository

    @Before
    fun setUp() {
        hilt.inject()
    }

    @Test
    fun setOffice_moveIntoRange_marksAttendance() {
        if (!hasLocationPermission()) grantLocationFromBanner()

        // Standing at the office with no office saved yet: check-in is locked.
        gps.moveTo(OFFICE)
        await(hasContentDescription("Locked. Set the office location first."))
        compose.onNodeWithText("Mark Attendance").performScrollTo().assertIsNotEnabled()

        // Setup phase: save the current GPS position as the office.
        compose.onNodeWithText("Set Office Location").performScrollTo().performClick()
        awaitText("Office location saved")
        awaitText("Lat: 23.7509, Lon: 90.3935")

        // Walk 120 m away: out of range, still locked.
        gps.moveTo(northOf(OFFICE, 120.0))
        awaitText("You are 120m away from the office")
        compose.onNodeWithText("OUT OF RANGE").performScrollTo()
        compose.onNodeWithText("Mark Attendance").performScrollTo().assertIsNotEnabled()

        // Walk back to 20 m: in range, unlocked.
        gps.moveTo(northOf(OFFICE, 20.0))
        awaitText("You are 20m away from the office")
        compose.onNodeWithText("IN RANGE").performScrollTo()
        compose.onNodeWithText("Mark Attendance").performScrollTo().assertIsEnabled().performClick()

        // Checked in: confirmation shown and the button locks for the rest of the day.
        awaitText("Attendance marked")
        await(hasContentDescription("Locked. Checked in at", substring = true))
        compose.onNodeWithText("Mark Attendance").performScrollTo().assertIsNotEnabled()
    }

    private fun hasLocationPermission() = ContextCompat.checkSelfPermission(
        compose.activity, Manifest.permission.ACCESS_FINE_LOCATION,
    ) == PackageManager.PERMISSION_GRANTED

    /** The screen explains first and asks only on tap: no system dialog until the user chooses to grant. */
    private fun grantLocationFromBanner() {
        val device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
        awaitText("Location permission needed")
        check(!device.hasObject(By.pkg(PERMISSION_CONTROLLER_PKG))) { "Permission dialog appeared without a tap" }

        compose.onNodeWithText("Grant permission").performClick()
        val allow = device.wait(Until.findObject(By.res(PERMISSION_UI_RES_PKG, ALLOW_FOREGROUND_ID)), TIMEOUT_MS)
            ?: device.wait(Until.findObject(By.res(PERMISSION_UI_RES_PKG, ALLOW_ID)), TIMEOUT_MS)
            ?: error("System permission dialog did not appear")
        allow.click()

        compose.waitUntil(TIMEOUT_MS) {
            compose.onAllNodes(hasText("Location permission needed")).fetchSemanticsNodes().isEmpty()
        }
    }

    private fun awaitText(text: String) = await(hasText(text))

    private fun await(matcher: SemanticsMatcher) {
        compose.waitUntil(TIMEOUT_MS) {
            compose.onAllNodes(matcher).fetchSemanticsNodes().isNotEmpty()
        }
    }
}
