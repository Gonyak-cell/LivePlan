package com.liveplan.widget.ui

import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceTheme
import androidx.glance.color.ColorProviders
import androidx.glance.material3.ColorProviders
import androidx.glance.unit.ColorProvider

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
    object Colors {
        val background = android.graphics.Color.parseColor("#1E1E1E")
        val backgroundVariant = android.graphics.Color.parseColor("#2A2A2A")
        val primary = android.graphics.Color.parseColor("#6200EE")
        val textPrimary = android.graphics.Color.WHITE
        val textSecondary = android.graphics.Color.parseColor("#B0B0B0")
        val textMuted = android.graphics.Color.parseColor("#808080")
        val overdue = android.graphics.Color.parseColor("#FF6B6B")
        val dueSoon = android.graphics.Color.parseColor("#FFB347")
        val doing = android.graphics.Color.parseColor("#4ECDC4")
        val p1 = android.graphics.Color.parseColor("#FF6B6B")
    }
}
