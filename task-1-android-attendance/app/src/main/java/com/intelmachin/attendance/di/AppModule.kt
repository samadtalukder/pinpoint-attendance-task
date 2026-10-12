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
import javax.inject.Singleton

private val Context.attendanceDataStore: DataStore<Preferences> by preferencesDataStore(name = "attendance")

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds abstract fun location(impl: FusedLocationRepository): LocationRepository
    @Binds abstract fun office(impl: DataStoreOfficeRepository): OfficeRepository
    @Binds abstract fun checkIn(impl: DataStoreCheckInRepository): CheckInRepository
}

@Module
@InstallIn(SingletonComponent::class)
object PlatformModule {
    @Provides @Singleton
    fun dataStore(@ApplicationContext context: Context): DataStore<Preferences> = context.attendanceDataStore

    @Provides @Singleton
    fun fusedClient(@ApplicationContext context: Context): FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    @Provides
    fun clock(): Clock = Clock.systemDefaultZone()
}
