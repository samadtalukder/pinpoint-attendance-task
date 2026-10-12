package com.intelmachin.attendance.ui.attendance.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.intelmachin.attendance.R
import com.intelmachin.attendance.domain.model.GeoPoint
import java.util.Locale

private val MapHeight = 140.dp
private val ButtonMinHeight = 56.dp
private val ButtonRadius = 16.dp
private const val ButtonStrokeAlpha = 0.65f
private const val DisabledStrokeAlpha = 0.25f

@Composable
fun OfficeContextCard(
    office: GeoPoint?,
    isSettingOffice: Boolean,
    canSetOffice: Boolean,
    onSetOffice: () -> Unit,
    modifier: Modifier = Modifier,
    map: @Composable (GeoPoint) -> Unit,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = stringResource(R.string.step_office_context),
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.weight(1f),
                )
                Box(Modifier.size(8.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primary))
            }

            OfficeMapArea(office, map)

            Text(
                text = stringResource(R.string.office_helper),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            val buttonEnabled = canSetOffice && !isSettingOffice
            // Mockup: pill-like outlined button, soft blue stroke, bold blue label, circled plus.
            OutlinedButton(
                onClick = onSetOffice,
                enabled = buttonEnabled,
                border = BorderStroke(
                    1.5.dp,
                    MaterialTheme.colorScheme.primary.copy(alpha = if (buttonEnabled) ButtonStrokeAlpha else DisabledStrokeAlpha),
                ),
                shape = RoundedCornerShape(ButtonRadius),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.primary),
                modifier = Modifier.fillMaxWidth().heightIn(min = ButtonMinHeight),
            ) {
                if (isSettingOffice) {
                    CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp)
                } else {
                    Icon(Icons.Outlined.AddCircleOutline, contentDescription = null, modifier = Modifier.size(20.dp))
                }
                Text(
                    text = stringResource(
                        if (isSettingOffice) R.string.setting_office_location else R.string.set_office_location,
                    ),
                    modifier = Modifier.padding(start = 10.dp),
                    fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}

@Composable
private fun OfficeMapArea(office: GeoPoint?, map: @Composable (GeoPoint) -> Unit) {
    val description = stringResource(R.string.office_map_description)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(MapHeight)
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .semantics { contentDescription = description },
        contentAlignment = Alignment.Center,
    ) {
        if (office != null) {
            map(office)
        } else {
            Text(
                text = stringResource(R.string.office_not_set),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        if (office != null) {
            CoordinatePill(office, Modifier.align(Alignment.Center))
        }
    }
}

@Composable
private fun CoordinatePill(office: GeoPoint, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(50),
        color = MaterialTheme.colorScheme.surface,
        shadowElevation = 4.dp,
    ) {
        Row(Modifier.padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(
                Icons.Outlined.LocationOn,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(16.dp),
            )
            Text(
                text = stringResource(
                    R.string.office_coordinates,
                    String.format(Locale.US, "%.4f", office.latitude),
                    String.format(Locale.US, "%.4f", office.longitude),
                ),
                style = MaterialTheme.typography.labelMedium,
                fontFamily = FontFamily.Monospace,
                modifier = Modifier.padding(start = 6.dp),
            )
        }
    }
}
