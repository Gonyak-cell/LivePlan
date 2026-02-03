package com.liveplan.widget.ui

import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Widget theme and design tokens
 * Aligned with LivePlan design system
 */
object WidgetTheme {
    // Spacing
    val paddingSmall = 8.dp
    val paddingMedium = 12.dp
    val paddingLarge = 16.dp

    // Corner radius
    val cornerRadius = 16.dp

    // Font sizes
    val fontSizeTitle = 16.sp
    val fontSizeBody = 14.sp
    val fontSizeCounter = 12.sp
    val fontSizeLarge = 32.sp

    // Colors (dark theme optimized for widgets)
    // Using Int constants for JVM test compatibility
    object Colors {
        const val background = 0xFF1E1E1E.toInt()
        const val backgroundVariant = 0xFF2A2A2A.toInt()
        const val primary = 0xFF6200EE.toInt()
        const val textPrimary = 0xFFFFFFFF.toInt()
        const val textSecondary = 0xFFB0B0B0.toInt()
        const val textMuted = 0xFF808080.toInt()
        const val overdue = 0xFFFF6B6B.toInt()
        const val dueSoon = 0xFFFFB347.toInt()
        const val doing = 0xFF4ECDC4.toInt()
        const val p1 = 0xFFFF6B6B.toInt()
    }
}
