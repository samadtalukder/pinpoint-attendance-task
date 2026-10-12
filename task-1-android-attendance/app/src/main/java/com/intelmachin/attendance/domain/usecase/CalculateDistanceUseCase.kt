package com.intelmachin.attendance.domain.usecase

import com.intelmachin.attendance.domain.model.GeoPoint
import javax.inject.Inject
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/** Great-circle distance in meters (haversine). */
class CalculateDistanceUseCase @Inject constructor() {
    operator fun invoke(from: GeoPoint, to: GeoPoint): Double {
        val lat1 = Math.toRadians(from.latitude)
        val lat2 = Math.toRadians(to.latitude)
        val dLat = lat2 - lat1
        val dLon = Math.toRadians(to.longitude - from.longitude)
        val a = sin(dLat / 2).pow(2) + cos(lat1) * cos(lat2) * sin(dLon / 2).pow(2)
        return 2 * EARTH_RADIUS_METERS * asin(sqrt(a))
    }

    private companion object {
        const val EARTH_RADIUS_METERS = 6_371_000.0
    }
}
