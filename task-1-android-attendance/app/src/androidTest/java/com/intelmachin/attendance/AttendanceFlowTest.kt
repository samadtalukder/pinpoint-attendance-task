package com.intelmachin.attendance

import android.Manifest
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.rule.GrantPermissionRule
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.fakes.FakeLocationRepository
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import javax.inject.Inject

private const val TIMEOUT_MS = 5_000L

/** Karwan Bazar, Dhaka. */
private val OFFICE = GeoPoint(23.7509, 90.3935)

/** Point roughly [meters] due north of [from] (1 deg latitude is about 111,195 m). */
private fun northOf(from: GeoPoint, meters: Double) = GeoPoint(from.latitude + meters / 111_195.0, from.longitude)

/**
 * End-to-end flow on a device with fake GPS, in-memory storage and a clock fixed inside the window:
 * set office -> walk away (locked) -> walk back within 50 m -> mark attendance.
 */
@HiltAndroidTest
class AttendanceFlowTest {

    @get:Rule(order = 0)
    val hilt = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val permissions: GrantPermissionRule = GrantPermissionRule.grant(
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION,
    )

    @get:Rule(order = 2)
    val compose = createAndroidComposeRule<MainActivity>()

    @Inject lateinit var gps: FakeLocationRepository

    @Before
    fun setUp() {
        hilt.inject()
    }

    @Test
    fun setOffice_moveIntoRange_marksAttendance() {
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

    private fun awaitText(text: String) = await(hasText(text))

    private fun await(matcher: SemanticsMatcher) {
        compose.waitUntil(TIMEOUT_MS) {
            compose.onAllNodes(matcher).fetchSemanticsNodes().isNotEmpty()
        }
    }
}
