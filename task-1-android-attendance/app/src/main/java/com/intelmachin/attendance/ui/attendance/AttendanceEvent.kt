package com.intelmachin.attendance.ui.attendance

import android.app.PendingIntent

/** One-shot request for the screen to perform a platform action. */
sealed interface AttendanceEvent {
    /** Show the system "turn on location" dialog. */
    data class ResolveGps(val resolution: PendingIntent) : AttendanceEvent

    /** Open the system location settings screen. */
    data object OpenLocationSettings : AttendanceEvent
}
