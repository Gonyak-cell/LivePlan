package com.liveplan.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

/**
 * LivePlan Brand Light Color Scheme
 */
private val LightColorScheme = lightColorScheme(
    // Primary colors
    primary = Primary500,
    onPrimary = Color.White,
    primaryContainer = Primary100,
    onPrimaryContainer = Primary900,

    // Secondary colors
    secondary = Primary400,
    onSecondary = Color.White,
    secondaryContainer = Primary50,
    onSecondaryContainer = Primary800,

    // Tertiary colors
    tertiary = Secondary500,
    onTertiary = Color.White,
    tertiaryContainer = Secondary100,
    onTertiaryContainer = Secondary900,

    // Background colors
    background = BackgroundColors.LightBackground,
    onBackground = Neutral900,
    surface = BackgroundColors.LightSurface,
    onSurface = Neutral900,
    surfaceVariant = BackgroundColors.LightSurfaceVariant,
    onSurfaceVariant = Neutral600,

    // Error colors
    error = Error,
    onError = Color.White,
    errorContainer = ErrorLight,
    onErrorContainer = ErrorDark,

    // Outline
    outline = Neutral300,
    outlineVariant = Neutral200,

    // Inverse colors
    inverseSurface = Neutral800,
    inverseOnSurface = Neutral100,
    inversePrimary = Primary200
)

/**
 * LivePlan Brand Dark Color Scheme
 */
private val DarkColorScheme = darkColorScheme(
    // Primary colors
    primary = Primary300,
    onPrimary = Primary900,
    primaryContainer = Primary800,
    onPrimaryContainer = Primary100,

    // Secondary colors
    secondary = Primary200,
    onSecondary = Primary900,
    secondaryContainer = Primary700,
    onSecondaryContainer = Primary100,

    // Tertiary colors
    tertiary = Secondary300,
    onTertiary = Secondary900,
    tertiaryContainer = Secondary700,
    onTertiaryContainer = Secondary100,

    // Background colors
    background = BackgroundColors.DarkBackground,
    onBackground = Neutral100,
    surface = BackgroundColors.DarkSurface,
    onSurface = Neutral100,
    surfaceVariant = BackgroundColors.DarkSurfaceVariant,
    onSurfaceVariant = Neutral400,

    // Error colors
    error = Error,
    onError = Color.White,
    errorContainer = Color(0xFF93000A),
    onErrorContainer = ErrorLight,

    // Outline
    outline = Neutral600,
    outlineVariant = Neutral700,

    // Inverse colors
    inverseSurface = Neutral100,
    inverseOnSurface = Neutral800,
    inversePrimary = Primary600
)

/**
 * LivePlan Shape System
 */
val LivePlanShapes = Shapes(
    extraSmall = RoundedCornerShape(Radius.xs),
    small = RoundedCornerShape(Radius.sm),
    medium = RoundedCornerShape(Radius.md),
    large = RoundedCornerShape(Radius.lg),
    extraLarge = RoundedCornerShape(Radius.xl)
)

/**
 * LivePlan Theme
 *
 * @param darkTheme Whether to use dark theme
 * @param dynamicColor Whether to use dynamic color (Android 12+). Default is false for brand consistency.
 * @param content The composable content
 */
@Composable
fun LivePlanTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color disabled by default for brand consistency
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = LivePlanShapes,
        content = content
    )
}
