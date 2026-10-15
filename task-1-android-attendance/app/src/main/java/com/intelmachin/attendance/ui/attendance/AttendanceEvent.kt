package com.intelmachin.attendance.ui.attendance

import com.intelmachin.attendance.domain.repository.GpsResolution

/** One-shot request for the screen to perform a platform action. */
sealed interface AttendanceEvent {
    /** Show the system "turn on location" dialog. */
    data class ResolveGps(val resolution: GpsResolution) : AttendanceEvent

    /** Open the system location settings screen. */
    data object OpenLocationSettings : AttendanceEvent
}
