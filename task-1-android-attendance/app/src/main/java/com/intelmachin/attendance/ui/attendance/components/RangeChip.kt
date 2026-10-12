package com.intelmachin.attendance.ui.attendance.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.intelmachin.attendance.R
import com.intelmachin.attendance.domain.AttendanceRules
import com.intelmachin.attendance.ui.attendance.formatDistance
import com.intelmachin.attendance.ui.theme.StatusColors
import kotlin.math.roundToInt

/** Status chip plus helper copy and the live distance sentence. State = icon + text + colour. */
@Composable
fun RangeStatusSection(
    distanceMeters: Double?,
    isInRange: Boolean?,
    isFixStale: Boolean,
    modifier: Modifier = Modifier,
) {
    val (label, helper, tint, container, icon) = when (isInRange) {
        true -> ChipStyle(
            R.string.chip_in_range, null,
            StatusColors.inRange, StatusColors.inRangeContainer, Icons.Filled.CheckCircle,
        )
        false -> ChipStyle(
            R.string.chip_out_of_range,
            stringResource(R.string.range_helper_out, AttendanceRules.OFFICE_RADIUS_METERS.roundToInt()),
            MaterialTheme.colorScheme.error, MaterialTheme.colorScheme.errorContainer, Icons.Filled.Cancel,
        )
        null -> ChipStyle(
            R.string.chip_unknown, stringResource(R.string.range_helper_unknown),
            MaterialTheme.colorScheme.onSurfaceVariant, MaterialTheme.colorScheme.surfaceVariant,
            Icons.Filled.HelpOutline,
        )
    }
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Surface(shape = RoundedCornerShape(50), color = container) {
            Row(Modifier.padding(horizontal = 12.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(16.dp))
                Text(
                    text = stringResource(label),
                    color = tint,
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 6.dp),
                )
            }
        }
        Text(
            text = distanceMeters?.let { stringResource(R.string.distance_away_text, formatDistance(it)) }
                ?: stringResource(R.string.distance_unavailable_text),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            textAlign = TextAlign.Center,
        )
        helper?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
        }
        if (isFixStale) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.Warning, contentDescription = null,
                    tint = MaterialTheme.colorScheme.error, modifier = Modifier.size(16.dp),
                )
                Text(
                    text = stringResource(R.string.stale_fix_warning),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(start = 6.dp),
                )
            }
        }
    }
}

private data class ChipStyle(
    val label: Int,
    /** Null when the sentence above already says everything (in range). */
    val helper: String?,
    val tint: androidx.compose.ui.graphics.Color,
    val container: androidx.compose.ui.graphics.Color,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
)
