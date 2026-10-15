package com.intelmachin.attendance.domain.repository

/** Checks whether device location settings allow high-accuracy GPS, and how the user can fix them. */
interface GpsSettingsChecker {
    suspend fun check(): GpsSettingsResult
}

sealed interface GpsSettingsResult {
    /** Location settings already satisfy the request. */
    data object AlreadyOn : GpsSettingsResult

    /** Launch [resolution] to show the system "turn on location" dialog. */
    data class NeedsResolution(val resolution: GpsResolution) : GpsSettingsResult

    /** No in-app dialog possible; send the user to the location settings screen. */
    data object Unavailable : GpsSettingsResult
}

/**
 * Opaque platform handle for the "turn on location" dialog. Domain never looks inside;
 * the data layer creates it and the UI layer launches it.
 */
class GpsResolution(val handle: Any)
