package com.intelmachin.attendance.fakes

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import com.intelmachin.attendance.di.ClockModule
import com.intelmachin.attendance.di.LocationModule
import com.intelmachin.attendance.di.StorageModule
import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.model.LocationFix
import com.intelmachin.attendance.domain.model.LocationStatus
import com.intelmachin.attendance.domain.repository.CheckInRepository
import com.intelmachin.attendance.domain.repository.LocationRepository
import com.intelmachin.attendance.domain.repository.OfficeRepository
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import dagger.hilt.testing.TestInstallIn
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.time.Clock
import java.time.LocalDateTime
import java.time.ZoneId
import javax.inject.Inject
import javax.inject.Singleton

/** 09:30 device-local time on 2026-10-12: inside the 09:00-10:30 window in any time zone. */
val TEST_CLOCK: Clock = ZoneId.systemDefault().let { zone ->
    Clock.fixed(LocalDateTime.of(2026, 10, 12, 9, 30).atZone(zone).toInstant(), zone)
}

/**
 * Fake GPS: the test moves the user by calling [moveTo]. Reports [LocationStatus.PermissionDenied] until the
 * app really holds the location permission, so the real system dialog drives the flow.
 */
@Singleton
class FakeLocationRepository @Inject constructor(
    @ApplicationContext private val context: Context,
) : LocationRepository {
    private var fix: LocationFix? = null
    private val state = MutableStateFlow(evaluate())
    override val status: StateFlow<LocationStatus> = state

    override fun refresh() {
        state.value = evaluate()
    }

    override suspend fun currentFix(): LocationFix? = (state.value as? LocationStatus.Available)?.fix

    fun moveTo(point: GeoPoint) {
        fix = LocationFix(point, accuracyMeters = 5f, isMock = false, timeMillis = TEST_CLOCK.millis())
        refresh()
    }

    private fun evaluate(): LocationStatus {
        val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        val current = fix
        return when {
            !granted -> LocationStatus.PermissionDenied
            current == null -> LocationStatus.Searching
            else -> LocationStatus.Available(current)
        }
    }
}

@Singleton
class InMemoryOfficeRepository @Inject constructor() : OfficeRepository {
    override val office = MutableStateFlow<GeoPoint?>(null)
    override suspend fun save(point: GeoPoint) { office.value = point }
}

@Singleton
class InMemoryCheckInRepository @Inject constructor() : CheckInRepository {
    override val lastCheckIn = MutableStateFlow<CheckIn?>(null)
    override suspend fun save(checkIn: CheckIn) { lastCheckIn.value = checkIn }
}

@Module
@TestInstallIn(components = [SingletonComponent::class], replaces = [LocationModule::class])
abstract class FakeLocationModule {
    @Binds abstract fun location(fake: FakeLocationRepository): LocationRepository
}

@Module
@TestInstallIn(components = [SingletonComponent::class], replaces = [StorageModule::class])
abstract class InMemoryStorageModule {
    @Binds abstract fun office(fake: InMemoryOfficeRepository): OfficeRepository
    @Binds abstract fun checkIn(fake: InMemoryCheckInRepository): CheckInRepository
}

@Module
@TestInstallIn(components = [SingletonComponent::class], replaces = [ClockModule::class])
object FixedClockModule {
    @Provides fun clock(): Clock = TEST_CLOCK
}
