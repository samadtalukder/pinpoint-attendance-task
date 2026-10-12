package com.intelmachin.attendance.ui.attendance.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.intelmachin.attendance.domain.model.GeoPoint
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint as OsmGeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker

private const val MAP_ZOOM = 17.0

/** osmdroid map centred on the saved office. Non-interactive: the card is the control surface. */
@Composable
fun OfficeMap(office: GeoPoint, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val mapView = remember {
        MapView(context).apply {
            setTileSource(TileSourceFactory.MAPNIK)
            setMultiTouchControls(false)
            isClickable = false
            controller.setZoom(MAP_ZOOM)
        }
    }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle, mapView) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_RESUME -> mapView.onResume()
                Lifecycle.Event.ON_PAUSE -> mapView.onPause()
                else -> Unit
            }
        }
        lifecycle.addObserver(observer)
        onDispose {
            lifecycle.removeObserver(observer)
            mapView.onDetach()
        }
    }
    AndroidView(
        modifier = modifier,
        factory = { mapView },
        update = { map ->
            val center = OsmGeoPoint(office.latitude, office.longitude)
            map.controller.setCenter(center)
            map.overlays.clear()
            map.overlays.add(Marker(map).apply { position = center; setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM) })
            map.invalidate()
        },
    )
}
