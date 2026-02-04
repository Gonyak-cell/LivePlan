package com.liveplan.ui.theme

import androidx.compose.ui.unit.dp

/**
 * LivePlan Spacing System
 * Based on 4px base unit
 */
object Spacing {
    val none = 0.dp
    val xs = 4.dp     // Extra small
    val sm = 8.dp     // Small
    val md = 12.dp    // Medium
    val lg = 16.dp    // Large
    val xl = 24.dp    // Extra large
    val xxl = 32.dp   // 2x Extra large
    val xxxl = 48.dp  // 3x Extra large

    // Semantic spacing
    val cardPadding = lg
    val screenPadding = lg
    val listItemPadding = md
    val iconTextGap = sm
    val sectionGap = xl
}

/**
 * LivePlan Border Radius System
 */
object Radius {
    val none = 0.dp
    val xs = 2.dp     // Extra small (chips, tags)
    val sm = 4.dp     // Small (badges)
    val md = 8.dp     // Medium (cards, buttons)
    val lg = 12.dp    // Large (dialogs, sheets)
    val xl = 16.dp    // Extra large (modals)
    val xxl = 24.dp   // 2x Extra large (full rounded)
    val full = 9999.dp // Fully rounded (pills, circles)
}

/**
 * LivePlan Elevation System
 */
object Elevation {
    val none = 0.dp
    val xs = 1.dp     // Subtle shadow
    val sm = 2.dp     // Small shadow (cards)
    val md = 6.dp     // Medium shadow (floating buttons)
    val lg = 12.dp    // Large shadow (dialogs)
    val xl = 24.dp    // Extra large shadow (modals)
}

/**
 * LivePlan Icon Sizes
 */
object IconSize {
    val xs = 12.dp    // Extra small (inline indicators)
    val sm = 16.dp    // Small (badge icons)
    val md = 20.dp    // Medium (default icons)
    val lg = 24.dp    // Large (action icons)
    val xl = 32.dp    // Extra large (feature icons)
    val xxl = 48.dp   // 2x Extra large (empty state icons)
}

/**
 * LivePlan Component Heights
 */
object ComponentHeight {
    val buttonSmall = 32.dp
    val buttonMedium = 40.dp
    val buttonLarge = 48.dp

    val inputField = 48.dp
    val listItem = 56.dp
    val toolbar = 56.dp

    val avatar = 40.dp
    val avatarSmall = 32.dp
    val avatarLarge = 56.dp
}
