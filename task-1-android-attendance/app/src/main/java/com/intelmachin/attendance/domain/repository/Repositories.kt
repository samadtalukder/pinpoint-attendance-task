package com.intelmachin.attendance.domain.repository

import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.model.LocationFix
import com.intelmachin.attendance.domain.model.LocationStatus
import kotlinx.coroutines.flow.Flow

interface LocationRepository {
    /** Live permission, GPS and fix state. Re-emits after [refresh]. */
    val status: Flow<LocationStatus>

    /** Re-reads permission and GPS state, e.g. after a permission dialog or settings change. */
    fun refresh()

    /** One fresh high-accuracy fix, or null when none can be obtained. */
    suspend fun currentFix(): LocationFix?
}

interface OfficeRepository {
    val office: Flow<GeoPoint?>
    suspend fun save(point: GeoPoint)
}

interface CheckInRepository {
    val lastCheckIn: Flow<CheckIn?>
    suspend fun save(checkIn: CheckIn)
}
