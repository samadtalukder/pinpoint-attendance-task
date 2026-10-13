package com.intelmachin.attendance.ui.attendance

import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.usecase.Eligibility

enum class LocationAvailability {
    Ready, Searching, PermissionDenied, PermissionPermanentlyDenied, GpsOff;

    /** True when location cannot work until the user acts; the screen shows only that prompt. */
    val blocksScreen: Boolean get() = this == PermissionDenied || this == PermissionPermanentlyDenied || this == GpsOff
}

/** One-off feedback shown once, then cleared with [AttendanceViewModel.onMessageShown]. */
enum class AttendanceMessage {
    OfficeSaved, OfficeNoFix, OfficeMockLocation, OfficeLowAccuracy, CheckedIn, CheckInRejected
}

data class AttendanceUiState(
    /** True until the first combined emission, so saved office data is not shown as missing. */
    val isLoading: Boolean = false,
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
