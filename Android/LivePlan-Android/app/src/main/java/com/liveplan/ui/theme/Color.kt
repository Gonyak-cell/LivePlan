package com.liveplan.ui.theme

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

// ============================================
// LivePlan Brand Color System
// Based on TaskCheck Design Tokens
// ============================================

// Primary Colors (Brand Blue)
val Primary50 = Color(0xFFE8F7FC)
val Primary100 = Color(0xFFC5ECF8)
val Primary200 = Color(0xFFA8E5F7)
val Primary300 = Color(0xFF6DD3F7)
val Primary400 = Color(0xFF3BB5E8)
val Primary500 = Color(0xFF1E9CD7)  // Main brand color
val Primary600 = Color(0xFF1A86B8)
val Primary700 = Color(0xFF156F99)
val Primary800 = Color(0xFF11597A)
val Primary900 = Color(0xFF0D435B)

// Secondary Colors (Complementary)
val Secondary50 = Color(0xFFF0F9FF)
val Secondary100 = Color(0xFFE0F2FE)
val Secondary200 = Color(0xFFBAE6FD)
val Secondary300 = Color(0xFF7DD3FC)
val Secondary400 = Color(0xFF38BDF8)
val Secondary500 = Color(0xFF0EA5E9)
val Secondary600 = Color(0xFF0284C7)
val Secondary700 = Color(0xFF0369A1)
val Secondary800 = Color(0xFF075985)
val Secondary900 = Color(0xFF0C4A6E)

// Neutral Colors (Gray scale)
val Neutral50 = Color(0xFFF9FAFB)
val Neutral100 = Color(0xFFF3F4F6)
val Neutral200 = Color(0xFFE5E7EB)
val Neutral300 = Color(0xFFD1D5DB)
val Neutral400 = Color(0xFF9CA3AF)
val Neutral500 = Color(0xFF6B7280)
val Neutral600 = Color(0xFF4B5563)
val Neutral700 = Color(0xFF374151)
val Neutral800 = Color(0xFF1F2937)
val Neutral900 = Color(0xFF111827)

// Semantic Colors
val Success = Color(0xFF10B981)
val SuccessLight = Color(0xFFD1FAE5)
val SuccessDark = Color(0xFF059669)

val Warning = Color(0xFFF59E0B)
val WarningLight = Color(0xFFFEF3C7)
val WarningDark = Color(0xFFD97706)

val Error = Color(0xFFEF4444)
val ErrorLight = Color(0xFFFEE2E2)
val ErrorDark = Color(0xFFDC2626)

val Info = Color(0xFF3B82F6)
val InfoLight = Color(0xFFDBEAFE)
val InfoDark = Color(0xFF2563EB)

// Priority Colors
object PriorityColors {
    // P1 - Highest (Red/Error)
    val P1Background = Color(0xFFFEE2E2)
    val P1Foreground = Color(0xFFDC2626)

    // P2 - High (Orange/Warning)
    val P2Background = Color(0xFFFEF3C7)
    val P2Foreground = Color(0xFFD97706)

    // P3 - Medium (Blue/Primary)
    val P3Background = Color(0xFFDBEAFE)
    val P3Foreground = Color(0xFF2563EB)

    // P4 - Low (Gray/Neutral)
    val P4Background = Color(0xFFF3F4F6)
    val P4Foreground = Color(0xFF6B7280)
}

// Workflow State Colors
object WorkflowColors {
    val TodoBackground = Color(0xFFF3F4F6)
    val TodoForeground = Color(0xFF6B7280)

    val DoingBackground = Color(0xFFDBEAFE)
    val DoingForeground = Color(0xFF2563EB)

    val DoneBackground = Color(0xFFD1FAE5)
    val DoneForeground = Color(0xFF059669)
}

// Brand Gradients
val BrandGradient = Brush.verticalGradient(
    colors = listOf(Primary300, Primary500)
)

val BrandGradientHorizontal = Brush.horizontalGradient(
    colors = listOf(Primary300, Primary500)
)

// Background Colors for Light/Dark themes
object BackgroundColors {
    // Light Theme
    val LightBackground = Color(0xFFFAFAFA)
    val LightSurface = Color(0xFFFFFFFF)
    val LightSurfaceVariant = Color(0xFFF3F4F6)

    // Dark Theme
    val DarkBackground = Color(0xFF121212)
    val DarkSurface = Color(0xFF1E1E1E)
    val DarkSurfaceVariant = Color(0xFF2A2A2A)
}

// Legacy colors for compatibility (will be removed in future)
@Deprecated("Use Primary200 instead", ReplaceWith("Primary200"))
val Purple80 = Primary200
@Deprecated("Use Neutral400 instead", ReplaceWith("Neutral400"))
val PurpleGrey80 = Neutral400
@Deprecated("Use Primary100 instead", ReplaceWith("Primary100"))
val Pink80 = Primary100

@Deprecated("Use Primary500 instead", ReplaceWith("Primary500"))
val Purple40 = Primary500
@Deprecated("Use Neutral600 instead", ReplaceWith("Neutral600"))
val PurpleGrey40 = Neutral600
@Deprecated("Use Primary700 instead", ReplaceWith("Primary700"))
val Pink40 = Primary700
