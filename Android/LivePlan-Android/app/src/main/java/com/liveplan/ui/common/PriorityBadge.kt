package com.liveplan.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.liveplan.core.model.Priority
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.ui.theme.PriorityColors
import com.liveplan.ui.theme.Radius

/**
 * Priority badge showing P1~P4 with color coding
 *
 * Colors (from theme):
 * - P1: Red (highest priority - Error)
 * - P2: Orange (high - Warning)
 * - P3: Blue (medium - Primary)
 * - P4: Gray (default/lowest - Neutral)
 */
@Composable
fun PriorityBadge(
    priority: Priority,
    modifier: Modifier = Modifier,
    showLabel: Boolean = true
) {
    val (backgroundColor, textColor) = getPriorityColors(priority)

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(Radius.sm))
            .background(backgroundColor)
            .padding(horizontal = 6.dp, vertical = 2.dp)
    ) {
        Text(
            text = if (showLabel) priority.name else priority.value.toString(),
            color = textColor,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

/**
 * Get colors for priority level using theme colors
 */
@Composable
private fun getPriorityColors(priority: Priority): Pair<Color, Color> {
    return when (priority) {
        Priority.P1 -> Pair(
            PriorityColors.P1Background,
            PriorityColors.P1Foreground
        )
        Priority.P2 -> Pair(
            PriorityColors.P2Background,
            PriorityColors.P2Foreground
        )
        Priority.P3 -> Pair(
            PriorityColors.P3Background,
            PriorityColors.P3Foreground
        )
        Priority.P4 -> Pair(
            MaterialTheme.colorScheme.surfaceVariant,
            MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * Get priority indicator color (solid color for icons/dots)
 */
fun getPriorityColor(priority: Priority): Color {
    return when (priority) {
        Priority.P1 -> PriorityColors.P1Foreground
        Priority.P2 -> PriorityColors.P2Foreground
        Priority.P3 -> PriorityColors.P3Foreground
        Priority.P4 -> PriorityColors.P4Foreground
    }
}

@Preview(showBackground = true)
@Composable
private fun PriorityBadgePreview() {
    LivePlanTheme {
        androidx.compose.foundation.layout.Row(
            horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(8.dp),
            modifier = Modifier.padding(16.dp)
        ) {
            PriorityBadge(Priority.P1)
            PriorityBadge(Priority.P2)
            PriorityBadge(Priority.P3)
            PriorityBadge(Priority.P4)
        }
    }
}
