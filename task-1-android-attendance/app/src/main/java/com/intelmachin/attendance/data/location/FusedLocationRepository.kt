package com.intelmachin.attendance.data.location

import android.Manifest
import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Looper
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import com.intelmachin.attendance.domain.model.GeoPoint
import com.intelmachin.attendance.domain.model.LocationFix
import com.intelmachin.attendance.domain.model.LocationStatus
import com.intelmachin.attendance.domain.repository.LocationRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull
import javax.inject.Inject
import javax.inject.Singleton

/** Adapter over Fused Location + LocationManager. Keeps Play Services out of domain and UI. */
@Singleton
class FusedLocationRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val client: FusedLocationProviderClient,
) : LocationRepository {

    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    /** StateFlow drops equal values, so [refresh] restarts updates only when permission really changed. */
    private val permissionGranted = MutableStateFlow(hasPermission())

    @OptIn(ExperimentalCoroutinesApi::class)
    override val status: Flow<LocationStatus> = permissionGranted.flatMapLatest { granted ->
        if (!granted) {
            flowOf(LocationStatus.PermissionDenied)
        } else {
            locationEnabled().flatMapLatest { enabled ->
                if (enabled) fixes().map<LocationFix, LocationStatus> { LocationStatus.Available(it) }
                    .onStart { emit(LocationStatus.Searching) }
                    .catch { if (it is SecurityException) emit(LocationStatus.PermissionDenied) else throw it }
                else flowOf(LocationStatus.GpsOff)
            }
        }
    }

    override fun refresh() {
        permissionGranted.value = hasPermission()
    }

    @SuppressLint("MissingPermission")
    override suspend fun currentFix(): LocationFix? {
        if (!hasPermission()) return null
        val cancellation = CancellationTokenSource()
        return try {
            withTimeoutOrNull(FIX_TIMEOUT_MS) {
                client.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, cancellation.token).await(cancellation)
            }?.toFix()
        } catch (_: SecurityException) {
            null
        } finally {
            cancellation.cancel()
        }
    }

    private fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED

    private fun locationEnabled(): Flow<Boolean> = callbackFlow {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, intent: Intent?) {
                trySend(LocationManagerCompat.isLocationEnabled(locationManager))
            }
        }
        val filter = IntentFilter().apply {
            addAction(LocationManager.PROVIDERS_CHANGED_ACTION)
            addAction(LocationManager.MODE_CHANGED_ACTION)
        }
        ContextCompat.registerReceiver(context, receiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
        trySend(LocationManagerCompat.isLocationEnabled(locationManager))
        awaitClose { context.unregisterReceiver(receiver) }
    }.distinctUntilChanged()

    @SuppressLint("MissingPermission")
    private fun fixes(): Flow<LocationFix> = callbackFlow {
        val callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { trySend(it.toFix()) }
            }
        }
        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, UPDATE_INTERVAL_MS).build()
        client.requestLocationUpdates(request, callback, Looper.getMainLooper())
        awaitClose { client.removeLocationUpdates(callback) }
    }

    private fun Location.toFix() = LocationFix(
        point = GeoPoint(latitude, longitude),
        accuracyMeters = accuracy,
        timeMillis = time,
        isMock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) isMock else @Suppress("DEPRECATION") isFromMockProvider,
    )

    private companion object {
        const val UPDATE_INTERVAL_MS = 2_000L
        const val FIX_TIMEOUT_MS = 10_000L
    }
}
