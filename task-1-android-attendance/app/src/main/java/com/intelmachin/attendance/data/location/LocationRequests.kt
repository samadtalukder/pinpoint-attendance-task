package com.intelmachin.attendance.data.location

import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.Priority

private const val UPDATE_INTERVAL_MS = 2_000L

/** The one request shape the app uses, for live updates and for the settings check. */
internal fun highAccuracyRequest(): LocationRequest =
    LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, UPDATE_INTERVAL_MS).build()
