package com.intelmachin.attendance.fakes

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
import dagger.hilt.components.SingletonComponent
import dagger.hilt.testing.TestInstallIn
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import javax.inject.Inject
import javax.inject.Singleton

/** 09:30 UTC on 2026-10-12: inside the 09:00-10:30 attendance window. */
val TEST_CLOCK: Clock = Clock.fixed(Instant.parse("2026-10-12T09:30:00Z"), ZoneOffset.UTC)

/** Fake GPS: the test moves the user by calling [moveTo]. */
@Singleton
class FakeLocationRepository @Inject constructor() : LocationRepository {
    private val state = MutableStateFlow<LocationStatus>(LocationStatus.Searching)
    override val status: StateFlow<LocationStatus> = state

    override fun refresh() = Unit
    override suspend fun currentFix(): LocationFix? = (state.value as? LocationStatus.Available)?.fix

    fun moveTo(point: GeoPoint) {
        state.value = LocationStatus.Available(
            LocationFix(point, accuracyMeters = 5f, isMock = false, timeMillis = TEST_CLOCK.millis()),
        )
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
