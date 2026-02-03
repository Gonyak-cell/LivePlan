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

/**
 * Priority badge showing P1~P4 with color coding
 *
 * Colors:
 * - P1: Red (highest priority)
 * - P2: Orange
 * - P3: Blue
 * - P4: Gray (default/lowest)
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
            .clip(RoundedCornerShape(4.dp))
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
 * Get colors for priority level
 */
@Composable
private fun getPriorityColors(priority: Priority): Pair<Color, Color> {
    return when (priority) {
        Priority.P1 -> Pair(
            Color(0xFFFFEBEE), // Light red background
            Color(0xFFD32F2F)  // Red text
        )
        Priority.P2 -> Pair(
            Color(0xFFFFF3E0), // Light orange background
            Color(0xFFF57C00)  // Orange text
        )
        Priority.P3 -> Pair(
            Color(0xFFE3F2FD), // Light blue background
            Color(0xFF1976D2)  // Blue text
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
        Priority.P1 -> Color(0xFFD32F2F) // Red
        Priority.P2 -> Color(0xFFF57C00) // Orange
        Priority.P3 -> Color(0xFF1976D2) // Blue
        Priority.P4 -> Color(0xFF757575) // Gray
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
