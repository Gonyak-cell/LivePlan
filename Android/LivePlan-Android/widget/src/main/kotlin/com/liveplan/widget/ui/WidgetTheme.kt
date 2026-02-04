package com.liveplan.widget.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.color.ColorProvider

/**
 * Widget theme and design tokens
 * Aligned with LivePlan brand design system
 */
object WidgetTheme {
    // Spacing
    val paddingSmall = 8.dp
    val paddingMedium = 12.dp
    val paddingLarge = 16.dp

    // Corner radius
    val cornerRadius = 16.dp
    val cornerRadiusSmall = 8.dp

    // Font sizes
    val fontSizeTitle = 16.sp
    val fontSizeBody = 14.sp
    val fontSizeCounter = 12.sp
    val fontSizeLarge = 32.sp

    // Brand color values (from LivePlan design tokens)
    private object BrandColors {
        // Primary (Brand Blue)
        val primary = Color(0xFF1E9CD7)
        val primaryLight = Color(0xFF6DD3F7)
        val primaryDark = Color(0xFF156F99)

        // Background
        val backgroundLight = Color(0xFFFAFAFA)
        val backgroundDark = Color(0xFF121212)
        val surfaceLight = Color(0xFFFFFFFF)
        val surfaceDark = Color(0xFF1E1E1E)
        val surfaceVariantDark = Color(0xFF2A2A2A)

        // Text
        val textPrimaryLight = Color(0xFF111827)
        val textPrimaryDark = Color(0xFFFFFFFF)
        val textSecondaryLight = Color(0xFF6B7280)
        val textSecondaryDark = Color(0xFFB0B0B0)
        val textMutedLight = Color(0xFF9CA3AF)
        val textMutedDark = Color(0xFF808080)

        // Semantic
        val error = Color(0xFFEF4444)
        val warning = Color(0xFFF59E0B)
        val success = Color(0xFF10B981)
        val info = Color(0xFF3B82F6)

        // Priority
        val p1 = Color(0xFFDC2626)
        val p2 = Color(0xFFD97706)
        val p3 = Color(0xFF2563EB)
        val p4 = Color(0xFF6B7280)
    }

    /**
     * Color providers for Glance widgets
     * Using ColorProvider(day, night) for light/dark mode support
     */
    object Colors {
        // Primary
        val primary = ColorProvider(day = BrandColors.primary, night = BrandColors.primaryLight)

        // Background
        val background = ColorProvider(
            day = BrandColors.backgroundLight,
            night = BrandColors.backgroundDark
        )
        val surface = ColorProvider(
            day = BrandColors.surfaceLight,
            night = BrandColors.surfaceDark
        )
        val surfaceVariant = ColorProvider(
            day = Color(0xFFF3F4F6),
            night = BrandColors.surfaceVariantDark
        )

        // Text
        val textPrimary = ColorProvider(
            day = BrandColors.textPrimaryLight,
            night = BrandColors.textPrimaryDark
        )
        val textSecondary = ColorProvider(
            day = BrandColors.textSecondaryLight,
            night = BrandColors.textSecondaryDark
        )
        val textMuted = ColorProvider(
            day = BrandColors.textMutedLight,
            night = BrandColors.textMutedDark
        )

        // Semantic
        val error = ColorProvider(day = BrandColors.error, night = BrandColors.error)
        val warning = ColorProvider(day = BrandColors.warning, night = BrandColors.warning)
        val success = ColorProvider(day = BrandColors.success, night = BrandColors.success)
        val overdue = ColorProvider(day = BrandColors.error, night = BrandColors.error)
        val dueSoon = ColorProvider(day = BrandColors.warning, night = BrandColors.warning)
        val doing = ColorProvider(day = BrandColors.info, night = BrandColors.info)

        // Priority
        val p1 = ColorProvider(day = BrandColors.p1, night = BrandColors.p1)
        val p2 = ColorProvider(day = BrandColors.p2, night = BrandColors.p2)
        val p3 = ColorProvider(day = BrandColors.p3, night = BrandColors.p3)
        val p4 = ColorProvider(day = BrandColors.p4, night = BrandColors.p4)

        // Legacy aliases for compatibility
        @Deprecated("Use surface instead", ReplaceWith("surface"))
        val backgroundVariant = surfaceVariant
    }
}
