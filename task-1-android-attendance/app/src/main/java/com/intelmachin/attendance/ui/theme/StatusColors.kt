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

/** Slate tones for the locked Mark Attendance card, as in the mockup. */
object LockedColors {
    private val dark @Composable get() = isSystemInDarkTheme()

    val container: Color @Composable get() = if (dark) Color(0xFF1C2129) else Color(0xFFF1F4F8)
    val border: Color @Composable get() = if (dark) Color(0xFF3A4352) else Color(0xFFC5CCD8)
    val hint: Color @Composable get() = if (dark) Color(0xFF7F8A9D) else Color(0xFF8A94A7)
    val button: Color @Composable get() = if (dark) Color(0xFF2E3644) else Color(0xFFCBD2DE)
    /** Helper copy under the range chip: soft slate, still >= 4.5:1 on the screen background. */
    val helper: Color @Composable get() = if (dark) Color(0xFF9AA5B8) else Color(0xFF68738A)
    val buttonContent: Color @Composable get() = if (dark) Color(0xFFAEB7C7) else Color(0xFF59647A)
}
