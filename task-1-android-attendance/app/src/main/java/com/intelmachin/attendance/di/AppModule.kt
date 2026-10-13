package com.intelmachin.attendance.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.intelmachin.attendance.data.location.FusedLocationRepository
import com.intelmachin.attendance.data.store.DataStoreCheckInRepository
import com.intelmachin.attendance.data.store.DataStoreOfficeRepository
import com.intelmachin.attendance.domain.AttendancePolicy
import com.intelmachin.attendance.domain.repository.CheckInRepository
import com.intelmachin.attendance.domain.repository.LocationRepository
import com.intelmachin.attendance.domain.repository.OfficeRepository
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import java.time.Clock
import java.time.Instant
import java.time.ZoneId
import javax.inject.Singleton

private val Context.attendanceDataStore: DataStore<Preferences> by preferencesDataStore(name = "attendance")

/** Real GPS. Swapped for a fake in instrumented tests. */
@Module
@InstallIn(SingletonComponent::class)
abstract class LocationModule {
    @Binds abstract fun location(impl: FusedLocationRepository): LocationRepository

    companion object {
        @Provides @Singleton
        fun fusedClient(@ApplicationContext context: Context): FusedLocationProviderClient =
            LocationServices.getFusedLocationProviderClient(context)
    }
}

@Module
@InstallIn(SingletonComponent::class)
abstract class StorageModule {
    @Binds abstract fun office(impl: DataStoreOfficeRepository): OfficeRepository
    @Binds abstract fun checkIn(impl: DataStoreCheckInRepository): CheckInRepository

    companion object {
        @Provides @Singleton
        fun dataStore(@ApplicationContext context: Context): DataStore<Preferences> = context.attendanceDataStore
    }
}

/** Switchable business rules; defaults come from [com.intelmachin.attendance.domain.AttendanceRules]. */
@Module
@InstallIn(SingletonComponent::class)
object PolicyModule {
    @Provides
    fun policy(): AttendancePolicy = AttendancePolicy()
}

/** System clock. Swapped for a fixed clock in instrumented tests. */
@Module
@InstallIn(SingletonComponent::class)
object ClockModule {
    @Provides
    fun clock(): Clock = SystemZoneClock
}

/** Reads the device zone on every call, so a timezone change takes effect without a process restart. */
private object SystemZoneClock : Clock() {
    override fun getZone(): ZoneId = ZoneId.systemDefault()
    override fun withZone(zone: ZoneId): Clock = system(zone)
    override fun instant(): Instant = Instant.now()
}
