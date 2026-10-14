package com.intelmachin.attendance.domain.repository

import android.app.PendingIntent

/** Checks whether device location settings allow high-accuracy GPS, and how the user can fix them. */
interface GpsSettingsChecker {
    suspend fun check(): GpsSettingsResult
}

sealed interface GpsSettingsResult {
    /** Location settings already satisfy the request. */
    data object AlreadyOn : GpsSettingsResult

    /** Launch [resolution] to show the system "turn on location" dialog. */
    data class NeedsResolution(val resolution: PendingIntent) : GpsSettingsResult

    /** No in-app dialog possible; send the user to the location settings screen. */
    data object Unavailable : GpsSettingsResult
}
