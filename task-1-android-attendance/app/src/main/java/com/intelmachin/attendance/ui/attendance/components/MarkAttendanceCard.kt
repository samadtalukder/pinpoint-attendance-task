package com.intelmachin.attendance.ui.attendance.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.intelmachin.attendance.R
import com.intelmachin.attendance.domain.AttendanceRules
import com.intelmachin.attendance.domain.usecase.Eligibility
import com.intelmachin.attendance.ui.attendance.formatClock
import com.intelmachin.attendance.ui.attendance.reasonText
import com.intelmachin.attendance.ui.theme.LockedColors
import com.intelmachin.attendance.ui.theme.StatusColors

private val CardRadius = 20.dp
private val ButtonMinHeight = 56.dp
private val ButtonRadius = 16.dp

@Composable
fun MarkAttendanceCard(
    eligibility: Eligibility,
    isWindowOpen: Boolean,
    isMarking: Boolean,
    onMark: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val unlocked = eligibility == Eligibility.Eligible
    // Card shows only the window, as in the mockup; the lock reason is read out by screen readers.
    val reason = eligibility.reasonText()
    val description = if (unlocked) stringResource(R.string.mark_unlocked_description)
    else stringResource(R.string.mark_locked_description, reason)
    val checkedIn = eligibility is Eligibility.AlreadyCheckedIn
    // Outside the window the lock and window hint fade to the slate locked tone, like the button.
    val hintColor = if (isWindowOpen) MaterialTheme.colorScheme.onSurfaceVariant else LockedColors.hint
    val borderColor = LockedColors.border

    Box(
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = description }
            .background(LockedColors.container, RoundedCornerShape(CardRadius))
            .dashedBorder(borderColor),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(
                imageVector = if (unlocked || checkedIn) Icons.Outlined.CheckCircle else Icons.Outlined.Lock,
                contentDescription = null,
                tint = if (unlocked || checkedIn) StatusColors.inRange else hintColor,
                modifier = Modifier.size(40.dp),
            )
            Button(
                onClick = onMark,
                enabled = unlocked && !isMarking,
                shape = RoundedCornerShape(ButtonRadius),
                colors = ButtonDefaults.buttonColors(
                    disabledContainerColor = LockedColors.button,
                    disabledContentColor = LockedColors.buttonContent,
                ),
                modifier = Modifier.fillMaxWidth().heightIn(min = ButtonMinHeight),
            ) {
                if (isMarking) {
                    CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp)
                }
                Text(
                    text = stringResource(if (isMarking) R.string.marking_attendance else R.string.mark_attendance),
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(start = if (isMarking) 8.dp else 0.dp),
                )
            }
            Text(
                text = stringResource(
                    R.string.available_window,
                    formatClock(AttendanceRules.WINDOW_START),
                    formatClock(AttendanceRules.WINDOW_END),
                ).uppercase(),
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.5.sp,
                color = hintColor,
            )
        }
    }
}

private fun Modifier.dashedBorder(color: Color): Modifier = drawBehind {
    drawRoundRect(
        color = color,
        cornerRadius = CornerRadius(CardRadius.toPx()),
        style = Stroke(width = 1.5.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(16f, 12f))),
    )
}
