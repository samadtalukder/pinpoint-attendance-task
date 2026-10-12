package com.intelmachin.attendance.domain

import java.time.LocalTime

object AttendanceRules {
    const val OFFICE_RADIUS_METERS = 50.0
    const val MAX_ACCURACY_METERS = 30f
    /** A fix older than this no longer counts as live (GPS updates stopped). */
    const val MAX_FIX_AGE_MILLIS = 15_000L
    val WINDOW_START: LocalTime = LocalTime.of(9, 0)
    val WINDOW_END: LocalTime = LocalTime.of(10, 30)
}
