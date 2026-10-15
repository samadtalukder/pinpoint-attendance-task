package com.intelmachin.attendance.ui.attendance

import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.usecase.Eligibility

enum class LocationAvailability {
    Ready, Searching, PermissionDenied, PreciseLocationNeeded, PermissionPermanentlyDenied, GpsOff;

    /** True when location cannot work until the user acts; the screen shows only that prompt. */
    val blocksScreen: Boolean get() = this == PermissionDenied || this == PreciseLocationNeeded || this == PermissionPermanentlyDenied || this == GpsOff
}

/** One-off feedback shown once, then cleared with [AttendanceViewModel.onMessageShown]. */
sealed interface AttendanceMessage {
    data object OfficeSaved : AttendanceMessage
    data object OfficeNoFix : AttendanceMessage
    data object OfficeMockLocation : AttendanceMessage
    data object OfficeLowAccuracy : AttendanceMessage
    data object CheckedIn : AttendanceMessage

    /** The tap-time re-check failed; [reason] says which rule, so the user knows what to fix. */
    data class CheckInRejected(val reason: Eligibility) : AttendanceMessage
    data object ActionFailed : AttendanceMessage
}

data class AttendanceUiState(
    val availability: LocationAvailability = LocationAvailability.Searching,
    val office: GeoPoint? = null,
    val distanceMeters: Double? = null,
    /** Null while distance is unknown. */
    val isInRange: Boolean? = null,
    /** Distance is from an old fix; GPS updates have stopped. */
    val isFixStale: Boolean = false,
    val eligibility: Eligibility = Eligibility.NoOffice,
    /** False outside 09:00-10:30; the card greys out its window hint. */
    val isWindowOpen: Boolean = true,
    val checkIn: CheckIn? = null,
    val isSettingOffice: Boolean = false,
    val isMarking: Boolean = false,
    val message: AttendanceMessage? = null,
) {
    val canMarkAttendance: Boolean get() = eligibility == Eligibility.Eligible && !isMarking
}
