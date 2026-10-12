package com.intelmachin.attendance.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/** Success tones meeting WCAG AA on the surface colors of each theme. */
object StatusColors {
    val inRange: Color
        @Composable get() = if (isSystemInDarkTheme()) Color(0xFF6FD28C) else Color(0xFF1B7F3B)
    val inRangeContainer: Color
        @Composable get() = if (isSystemInDarkTheme()) Color(0xFF123A21) else Color(0xFFDDF4E4)
}
