package com.intelmachin.attendance.ui.attendance.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.intelmachin.attendance.domain.model.GeoPoint
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint as OsmGeoPoint
import org.osmdroid.views.CustomZoomButtonsController
import org.osmdroid.views.MapView

private const val MAP_ZOOM = 17.0

/** osmdroid map centred on the saved office. Static background: no marker, zoom buttons or gestures; the Lat/Lon pill marks the spot. */
@Composable
fun OfficeMap(office: GeoPoint, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val mapView = remember {
        MapView(context).apply {
            setTileSource(TileSourceFactory.MAPNIK)
            setMultiTouchControls(false)
            zoomController.setVisibility(CustomZoomButtonsController.Visibility.NEVER)
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
    Box(modifier) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { mapView },
            update = { map ->
                map.controller.setCenter(OsmGeoPoint(office.latitude, office.longitude))
            },
        )
        // osmdroid zooms on double tap and drags on its own gesture detector, which
        // setMultiTouchControls(false) does not turn off. This overlay takes the touches first
        // and consumes nothing, so the page still scrolls and the map stays fixed.
        Box(Modifier.fillMaxSize().pointerInput(Unit) {})
    }
}
