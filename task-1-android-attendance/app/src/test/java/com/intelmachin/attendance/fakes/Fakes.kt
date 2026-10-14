package com.intelmachin.attendance.fakes

import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.model.LocationFix
import com.intelmachin.attendance.domain.model.LocationStatus
import com.intelmachin.attendance.domain.repository.CheckInRepository
import com.intelmachin.attendance.domain.repository.GpsSettingsChecker
import com.intelmachin.attendance.domain.repository.GpsSettingsResult
import com.intelmachin.attendance.domain.repository.LocationRepository
import com.intelmachin.attendance.domain.repository.OfficeRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset

val OFFICE = GeoPoint(23.7806, 90.4193)

/** Point roughly [meters] due north of [from] (1 deg latitude is about 111,195 m). */
fun northOf(from: GeoPoint, meters: Double) = GeoPoint(from.latitude + meters / 111_195.0, from.longitude)

/** Fix taken at the given UTC time on 2026-10-12; default matches the default test clock. */
fun fix(point: GeoPoint, accuracy: Float = 5f, mock: Boolean = false, at: String = "09:30") =
    LocationFix(point, accuracy, mock, Instant.parse("2026-10-12T${at}:00Z").toEpochMilli())

/** UTC clock fixed at the given UTC time on 2026-10-12. */
fun clockAt(time: String): Clock = Clock.fixed(Instant.parse("2026-10-12T${time}:00Z"), ZoneOffset.UTC)

class FakeLocationRepository(initial: LocationStatus = LocationStatus.Searching) : LocationRepository {
    private val state = MutableStateFlow(initial)
    override val status: StateFlow<LocationStatus> = state
    var fixResult: LocationFix? = null
    var refreshCount = 0

    override fun refresh() { refreshCount++ }
    override suspend fun currentFix(): LocationFix? = fixResult
    fun emit(status: LocationStatus) { state.value = status }
}

class FakeGpsSettingsChecker(var result: GpsSettingsResult = GpsSettingsResult.AlreadyOn) : GpsSettingsChecker {
    override suspend fun check(): GpsSettingsResult = result
}

class FakeOfficeRepository(initial: GeoPoint? = null) : OfficeRepository {
    private val state = MutableStateFlow(initial)
    override val office: StateFlow<GeoPoint?> = state
    override suspend fun save(point: GeoPoint) { state.value = point }
}

class FakeCheckInRepository(initial: CheckIn? = null) : CheckInRepository {
    private val state = MutableStateFlow(initial)
    override val lastCheckIn: StateFlow<CheckIn?> = state
    override suspend fun save(checkIn: CheckIn) { state.value = checkIn }
}
