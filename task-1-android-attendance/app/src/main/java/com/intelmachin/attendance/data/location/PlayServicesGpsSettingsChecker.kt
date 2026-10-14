package com.intelmachin.attendance.data.location

import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.SettingsClient
import com.intelmachin.attendance.domain.repository.GpsSettingsChecker
import com.intelmachin.attendance.domain.repository.GpsSettingsResult
import kotlinx.coroutines.tasks.await
import javax.inject.Inject

/** Adapter over the Play Services settings client. Keeps it out of UI and domain. */
class PlayServicesGpsSettingsChecker @Inject constructor(
    private val client: SettingsClient,
) : GpsSettingsChecker {

    override suspend fun check(): GpsSettingsResult {
        val request = LocationSettingsRequest.Builder()
            .addLocationRequest(highAccuracyRequest())
            .setAlwaysShow(true)
            .build()
        return try {
            client.checkLocationSettings(request).await()
            GpsSettingsResult.AlreadyOn
        } catch (e: ResolvableApiException) {
            GpsSettingsResult.NeedsResolution(e.resolution)
        } catch (_: ApiException) {
            GpsSettingsResult.Unavailable
        }
    }
}
