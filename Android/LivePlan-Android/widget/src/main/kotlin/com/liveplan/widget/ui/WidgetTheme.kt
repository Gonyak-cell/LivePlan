package com.liveplan.widget.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.color.ColorProvider

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

    // Raw color values for reference
    private object RawColors {
        val background = Color(0xFF1E1E1E)
        val backgroundVariant = Color(0xFF2A2A2A)
        val primary = Color(0xFF6200EE)
        val textPrimary = Color(0xFFFFFFFF)
        val textSecondary = Color(0xFFB0B0B0)
        val textMuted = Color(0xFF808080)
        val overdue = Color(0xFFFF6B6B)
        val dueSoon = Color(0xFFFFB347)
        val doing = Color(0xFF4ECDC4)
        val p1 = Color(0xFFFF6B6B)
    }

    /**
     * Color providers for Glance widgets
     * Using ColorProvider(day, night) which is the public API
     */
    object Colors {
        val background = ColorProvider(day = RawColors.background, night = RawColors.background)
        val backgroundVariant = ColorProvider(day = RawColors.backgroundVariant, night = RawColors.backgroundVariant)
        val primary = ColorProvider(day = RawColors.primary, night = RawColors.primary)
        val textPrimary = ColorProvider(day = RawColors.textPrimary, night = RawColors.textPrimary)
        val textSecondary = ColorProvider(day = RawColors.textSecondary, night = RawColors.textSecondary)
        val textMuted = ColorProvider(day = RawColors.textMuted, night = RawColors.textMuted)
        val overdue = ColorProvider(day = RawColors.overdue, night = RawColors.overdue)
        val dueSoon = ColorProvider(day = RawColors.dueSoon, night = RawColors.dueSoon)
        val doing = ColorProvider(day = RawColors.doing, night = RawColors.doing)
        val p1 = ColorProvider(day = RawColors.p1, night = RawColors.p1)
    }
}
