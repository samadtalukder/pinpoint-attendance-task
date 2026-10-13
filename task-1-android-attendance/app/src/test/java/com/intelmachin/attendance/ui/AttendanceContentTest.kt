package com.intelmachin.attendance.ui

import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.assertIsDisplayed
import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.usecase.Eligibility
import com.intelmachin.attendance.ui.attendance.AttendanceContent
import com.intelmachin.attendance.ui.attendance.AttendanceUiState
import com.intelmachin.attendance.ui.attendance.LocationAvailability
import com.intelmachin.attendance.ui.theme.AttendanceTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], qualifiers = "w411dp-h2000dp")
class AttendanceContentTest {
    @get:Rule val compose = createComposeRule()

    private val office = GeoPoint(40.7128, -74.0060)
    private val outOfRange = AttendanceUiState(
        availability = LocationAvailability.Ready,
        office = office,
        distanceMeters = 120.0,
        isInRange = false,
        eligibility = Eligibility.OutOfRange,
    )
    private val unlocked = outOfRange.copy(
        distanceMeters = 12.0, isInRange = true, eligibility = Eligibility.Eligible,
    )

    private var setOfficeClicks = 0
    private var markClicks = 0
    private var grantClicks = 0
    private var settingsClicks = 0
    private var gpsClicks = 0

    private fun show(state: AttendanceUiState) {
        compose.setContent {
            AttendanceTheme {
                AttendanceContent(
                    state = state,
                    onSetOffice = { setOfficeClicks++ },
                    onMarkAttendance = { markClicks++ },
                    onGrantPermission = { grantClicks++ },
                    onOpenSettings = { settingsClicks++ },
                    onEnableGps = { gpsClicks++ },
                    officeMap = {},
                )
            }
        }
    }

    @Test
    fun `out of range shows locked card, distance text and chip`() {
        show(outOfRange)
        compose.onNodeWithText("Mark Attendance").assertIsNotEnabled()
        compose.onNodeWithText("You are 120m away from the office").assertIsDisplayed()
        compose.onNodeWithText("OUT OF RANGE").assertIsDisplayed()
        compose.onNodeWithText("Move within 50 meters of the office.").assertDoesNotExist()
        compose.onNodeWithContentDescription("Locked. Move within 50 meters of the office.").assertExists()
        compose.onNodeWithText("Lat: 40.7128, Lon: -74.0060").assertIsDisplayed()
        compose.onNodeWithText("AVAILABLE 09:00 AM - 10:30 AM").assertIsDisplayed()
    }

    @Test
    fun `in range inside window unlocks and fires callback`() {
        show(unlocked)
        compose.onNodeWithText("IN RANGE").assertIsDisplayed()
        compose.onNodeWithText("You are within the office radius. Check-in is allowed.").assertDoesNotExist()
        compose.onNodeWithText("GPS accuracy", substring = true).assertDoesNotExist()
        compose.onNodeWithText("Mark Attendance").assertIsEnabled().performClick()
        assertEquals(1, markClicks)
    }

    @Test
    fun `outside window stays locked even when in range`() {
        show(unlocked.copy(eligibility = Eligibility.OutsideWindow))
        compose.onNodeWithText("Mark Attendance").assertIsNotEnabled()
        compose.onNodeWithText("IN RANGE").assertIsDisplayed()
    }

    @Test
    fun `mock location reason is announced to screen readers`() {
        show(unlocked.copy(eligibility = Eligibility.MockLocation))
        compose.onNodeWithContentDescription("Locked. Mock location detected. Turn off mock locations to continue.").assertExists()
    }

    @Test
    fun `stale fix shows warning and locked reason`() {
        show(unlocked.copy(isFixStale = true, eligibility = Eligibility.StaleFix))
        compose.onNodeWithText("GPS signal lost. Distance may be out of date.").assertIsDisplayed()
        compose.onNodeWithContentDescription("Locked. GPS signal lost. Waiting for a fresh location.").assertExists()
        compose.onNodeWithText("Mark Attendance").assertIsNotEnabled()
    }

    @Test
    fun `loading shows progress and hides cards`() {
        show(AttendanceUiState(isLoading = true))
        compose.onNodeWithContentDescription("Loading attendance").assertIsDisplayed()
        compose.onNodeWithText("Set Office Location").assertDoesNotExist()
        compose.onNodeWithText("Mark Attendance").assertDoesNotExist()
    }

    @Test
    fun `permission denied shows banner with grant action and disables set office`() {
        show(AttendanceUiState(availability = LocationAvailability.PermissionDenied))
        compose.onNodeWithText("Location permission needed").assertIsDisplayed()
        compose.onNodeWithText("Set Office Location").assertDoesNotExist()
        compose.onNodeWithText("Mark Attendance").assertDoesNotExist()
        compose.onNodeWithText("Grant permission").performClick()
        assertEquals(1, grantClicks)
    }

    @Test
    fun `permanently denied offers open settings`() {
        show(AttendanceUiState(availability = LocationAvailability.PermissionPermanentlyDenied))
        compose.onNodeWithText("Location permission is blocked").assertIsDisplayed()
        compose.onNodeWithText("Set Office Location").assertDoesNotExist()
        compose.onNodeWithText("Open settings").performClick()
        assertEquals(1, settingsClicks)
    }

    @Test
    fun `gps off offers enable gps`() {
        show(AttendanceUiState(availability = LocationAvailability.GpsOff))
        compose.onNodeWithText("GPS is turned off").assertIsDisplayed()
        compose.onNodeWithText("Set Office Location").assertDoesNotExist()
        compose.onNodeWithText("Mark Attendance").assertDoesNotExist()
        compose.onNodeWithText("DISTANCE UNKNOWN").assertDoesNotExist()
        compose.onNodeWithText("Enable GPS").performClick()
        assertEquals(1, gpsClicks)
    }

    @Test
    fun `searching shows progress copy and no action`() {
        show(AttendanceUiState(availability = LocationAvailability.Searching))
        compose.onNodeWithText("Finding your location…").assertIsDisplayed()
        compose.onNodeWithText("DISTANCE UNKNOWN").assertIsDisplayed()
    }

    @Test
    fun `ready location hides banner and allows setting office`() {
        show(AttendanceUiState(availability = LocationAvailability.Ready))
        compose.onNodeWithText("Location permission needed").assertDoesNotExist()
        compose.onNodeWithText("No office location set yet").assertIsDisplayed()
        compose.onNodeWithText("Set Office Location").assertIsEnabled().performClick()
        assertEquals(1, setOfficeClicks)
    }

    @Test
    fun `office already set keeps the set office label and stays re-settable`() {
        show(outOfRange)
        compose.onNodeWithText("Set Office Location").assertIsEnabled().performClick()
        assertEquals(1, setOfficeClicks)
    }

    @Test
    fun `already checked in is locked and announces check-in time`() {
        show(unlocked.copy(eligibility = Eligibility.AlreadyCheckedIn(CheckIn(1_760_000_000_000)), checkIn = CheckIn(1_760_000_000_000)))
        compose.onNodeWithText("Mark Attendance").assertIsNotEnabled()
        compose.onNodeWithContentDescription("Locked. Checked in at", substring = true).assertExists()
        compose.onNodeWithText("CHECKED IN AT", substring = true).assertIsDisplayed()
        compose.onNodeWithText("AVAILABLE", substring = true).assertDoesNotExist()
    }
}
