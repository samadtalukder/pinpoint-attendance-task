package com.intelmachin.attendance.data.store

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.doublePreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.longPreferencesKey
import com.intelmachin.attendance.domain.model.CheckIn
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.repository.CheckInRepository
import com.intelmachin.attendance.domain.repository.OfficeRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import java.io.IOException
import javax.inject.Inject

/** A corrupt or unreadable file reads as "nothing saved" instead of crashing the collector. */
private val DataStore<Preferences>.safeData: Flow<Preferences>
    get() = data.catch { if (it is IOException) emit(emptyPreferences()) else throw it }

class DataStoreOfficeRepository @Inject constructor(
    private val store: DataStore<Preferences>,
) : OfficeRepository {

    override val office: Flow<GeoPoint?> = store.safeData.map { prefs ->
        val lat = prefs[LATITUDE]
        val lon = prefs[LONGITUDE]
        if (lat != null && lon != null) GeoPoint(lat, lon) else null
    }

    override suspend fun save(point: GeoPoint) {
        store.edit {
            it[LATITUDE] = point.latitude
            it[LONGITUDE] = point.longitude
        }
    }

    private companion object {
        val LATITUDE = doublePreferencesKey("office_latitude")
        val LONGITUDE = doublePreferencesKey("office_longitude")
    }
}

class DataStoreCheckInRepository @Inject constructor(
    private val store: DataStore<Preferences>,
) : CheckInRepository {

    override val lastCheckIn: Flow<CheckIn?> = store.safeData.map { prefs ->
        prefs[LAST_CHECK_IN]?.let(::CheckIn)
    }

    override suspend fun save(checkIn: CheckIn) {
        store.edit { it[LAST_CHECK_IN] = checkIn.epochMillis }
    }

    private companion object {
        val LAST_CHECK_IN = longPreferencesKey("last_check_in_epoch_millis")
    }
}
