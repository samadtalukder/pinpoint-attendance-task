package com.intelmachin.attendance.ui.attendance

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.res.stringResource
import com.intelmachin.attendance.R
import com.intelmachin.attendance.domain.AttendanceRules
import com.intelmachin.attendance.domain.usecase.Eligibility
import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId
import java.util.Locale
import java.time.format.DateTimeFormatter
import kotlin.math.roundToInt

/** Always 12-hour with AM/PM ("09:00 AM"), as in the mockup, even on 24-hour devices. */
private val TimeFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("hh:mm a", Locale.ENGLISH)

@Composable
fun formatClock(time: LocalTime): String = remember(time) { TimeFormatter.format(time) }

@Composable
fun formatCheckInTime(epochMillis: Long): String = remember(epochMillis) {
    TimeFormatter.format(Instant.ofEpochMilli(epochMillis).atZone(ZoneId.systemDefault()))
}

/** "120m" under 1 km, "1.2km" above. Ring centre and live sentence share this. */
@Composable
fun formatDistance(meters: Double): String =
    if (meters < METERS_PER_KM) stringResource(R.string.distance_meters, meters.roundToInt())
    else stringResource(R.string.distance_kilometers, meters / METERS_PER_KM)

/** Why the Mark Attendance card is locked, or a ready hint when unlocked. */
@Composable
fun Eligibility.reasonText(): String = when (this) {
    Eligibility.Eligible -> stringResource(R.string.reason_ready)
    Eligibility.NoOffice -> stringResource(R.string.reason_no_office)
    Eligibility.NoFix -> stringResource(R.string.reason_no_fix)
    Eligibility.StaleFix -> stringResource(R.string.reason_stale_fix)
    Eligibility.MockLocation -> stringResource(R.string.reason_mock_location)
    is Eligibility.LowAccuracy -> stringResource(R.string.reason_low_accuracy, accuracyMeters.roundToInt())
    Eligibility.OutOfRange -> stringResource(
        R.string.reason_out_of_range, AttendanceRules.OFFICE_RADIUS_METERS.roundToInt(),
    )
    Eligibility.OutsideWindow -> stringResource(
        R.string.reason_outside_window,
        formatClock(AttendanceRules.WINDOW_START),
        formatClock(AttendanceRules.WINDOW_END),
    )
    is Eligibility.AlreadyCheckedIn ->
        stringResource(R.string.checked_in_at, formatCheckInTime(checkIn.epochMillis))
}

@Composable
fun AttendanceMessage.text(): String = when (this) {
    AttendanceMessage.OfficeSaved -> stringResource(R.string.message_office_saved)
    AttendanceMessage.OfficeNoFix -> stringResource(R.string.message_office_no_fix)
    AttendanceMessage.OfficeMockLocation -> stringResource(R.string.message_office_mock)
    AttendanceMessage.OfficeLowAccuracy -> stringResource(R.string.message_office_low_accuracy)
    AttendanceMessage.CheckedIn -> stringResource(R.string.message_checked_in)
    is AttendanceMessage.CheckInRejected -> reason.reasonText()
    AttendanceMessage.ActionFailed -> stringResource(R.string.message_action_failed)
}

private const val METERS_PER_KM = 1_000.0
