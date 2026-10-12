package com.intelmachin.attendance.ui.attendance.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.intelmachin.attendance.R
import com.intelmachin.attendance.domain.AttendanceRules
import com.intelmachin.attendance.ui.attendance.formatDistance
import com.intelmachin.attendance.ui.theme.StatusColors

private val RingSize = 132.dp
private val RingStroke = 6.dp
private const val FULL_SWEEP = 360f
private const val START_ANGLE = -90f

/** Arc length is presentation only: full when inside the radius, shrinking as you move away. */
private fun progress(distanceMeters: Double?): Float = when {
    distanceMeters == null -> 0f
    distanceMeters <= AttendanceRules.OFFICE_RADIUS_METERS -> 1f
    else -> (AttendanceRules.OFFICE_RADIUS_METERS / distanceMeters).toFloat()
}

@Composable
fun DistanceRing(distanceMeters: Double?, isInRange: Boolean?, modifier: Modifier = Modifier) {
    val color = when (isInRange) {
        true -> StatusColors.inRange
        false -> MaterialTheme.colorScheme.error
        null -> MaterialTheme.colorScheme.outline
    }
    val track = MaterialTheme.colorScheme.surfaceVariant
    val value = distanceMeters?.let { formatDistance(it) } ?: stringResource(R.string.distance_unknown)
    val away = stringResource(R.string.distance_away_label)
    val rangeWord = stringResource(
        when (isInRange) {
            true -> R.string.chip_in_range
            false -> R.string.chip_out_of_range
            null -> R.string.chip_unknown
        },
    )
    val description = stringResource(R.string.ring_description, "$value $away", rangeWord)

    Box(
        modifier = modifier.size(RingSize).clearAndSetSemantics { contentDescription = description },
        contentAlignment = Alignment.Center,
    ) {
        Canvas(Modifier.size(RingSize).padding(RingStroke / 2)) {
            val stroke = Stroke(width = RingStroke.toPx(), cap = StrokeCap.Round)
            drawArc(track, START_ANGLE, FULL_SWEEP, useCenter = false, style = stroke, topLeft = Offset.Zero, size = Size(size.width, size.height))
            drawArc(
                color, START_ANGLE, FULL_SWEEP * progress(distanceMeters), useCenter = false, style = stroke,
                topLeft = Offset.Zero, size = Size(size.width, size.height),
            )
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(value, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            Text(away, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
