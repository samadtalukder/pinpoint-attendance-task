package com.intelmachin.attendance.ui.attendance.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GpsOff
import androidx.compose.material.icons.filled.LocationDisabled
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.intelmachin.attendance.R
import com.intelmachin.attendance.ui.attendance.LocationAvailability

private val MinTouchTarget = 48.dp

private data class BannerContent(
    val icon: ImageVector?,
    val title: Int,
    val body: Int,
    val action: Int?,
)

/** Explains a permission or hardware problem and offers the next action. Hidden when location is ready. */
@Composable
fun StatusBanner(
    availability: LocationAvailability,
    onGrantPermission: () -> Unit,
    onOpenSettings: () -> Unit,
    onEnableGps: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val content = when (availability) {
        LocationAvailability.Ready -> return
        LocationAvailability.PermissionDenied ->
            BannerContent(Icons.Filled.LocationDisabled, R.string.permission_denied_title, R.string.permission_denied_body, R.string.action_grant_permission)
        LocationAvailability.PreciseLocationNeeded ->
            BannerContent(Icons.Filled.LocationDisabled, R.string.precise_location_title, R.string.precise_location_body, R.string.action_allow_precise)
        LocationAvailability.PermissionPermanentlyDenied ->
            BannerContent(Icons.Filled.LocationDisabled, R.string.permission_blocked_title, R.string.permission_blocked_body, R.string.action_open_settings)
        LocationAvailability.GpsOff ->
            BannerContent(Icons.Filled.GpsOff, R.string.gps_off_title, R.string.gps_off_body, R.string.action_enable_gps)
        LocationAvailability.Searching ->
            BannerContent(null, R.string.searching_title, R.string.searching_body, null)
    }
    val onAction = when (availability) {
        LocationAvailability.PermissionDenied, LocationAvailability.PreciseLocationNeeded -> onGrantPermission
        LocationAvailability.PermissionPermanentlyDenied -> onOpenSettings
        LocationAvailability.GpsOff -> onEnableGps
        else -> ({})
    }
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
    ) {
        Column(Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (content.icon != null) {
                    Icon(content.icon, contentDescription = null, modifier = Modifier.size(24.dp))
                } else {
                    CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp)
                }
                Text(
                    text = stringResource(content.title),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 12.dp),
                )
            }
            Text(
                text = stringResource(content.body),
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
            )
            if (content.action != null) {
                Button(
                    onClick = onAction,
                    modifier = Modifier.align(Alignment.CenterHorizontally).padding(top = 12.dp).heightIn(min = MinTouchTarget),
                ) {
                    Text(stringResource(content.action))
                }
            }
        }
    }
}
