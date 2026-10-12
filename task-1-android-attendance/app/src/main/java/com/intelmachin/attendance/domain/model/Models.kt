package com.intelmachin.attendance.domain.model

data class GeoPoint(val latitude: Double, val longitude: Double)

data class LocationFix(
    val point: GeoPoint,
    val accuracyMeters: Float,
    val isMock: Boolean,
    /** Wall-clock time of the fix, epoch millis. */
    val timeMillis: Long,
)

/** Moment of a successful check-in, as epoch millis. */
data class CheckIn(val epochMillis: Long)

sealed interface LocationStatus {
    data object PermissionDenied : LocationStatus
    data object GpsOff : LocationStatus
    data object Searching : LocationStatus
    data class Available(val fix: LocationFix) : LocationStatus
}
