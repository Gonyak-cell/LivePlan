package com.liveplan.ui.common

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.liveplan.R
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import com.liveplan.ui.theme.LivePlanTheme
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Task row component displaying:
 * - Checkbox for completion
 * - Title
 * - Due date (if present)
 * - Priority badge (if not P4)
 * - Recurring indicator (if recurring)
 */
@Composable
fun TaskRow(
    task: Task,
    isCompleted: Boolean,
    onToggleComplete: () -> Unit,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val priorityColor = getPriorityColor(task.priority)

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Checkbox with priority color
            Checkbox(
                checked = isCompleted,
                onCheckedChange = { onToggleComplete() },
                colors = CheckboxDefaults.colors(
                    checkedColor = priorityColor,
                    uncheckedColor = priorityColor.copy(alpha = 0.6f)
                )
            )

            Spacer(modifier = Modifier.width(8.dp))

            // Title and metadata
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    // Title
                    Text(
                        text = task.title,
                        style = MaterialTheme.typography.bodyLarge,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        textDecoration = if (isCompleted) TextDecoration.LineThrough else null,
                        color = if (isCompleted) {
                            MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                        } else {
                            MaterialTheme.colorScheme.onSurface
                        },
                        modifier = Modifier.weight(1f, fill = false)
                    )

                    // Recurring indicator
                    if (task.isRecurring) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = stringResource(R.string.task_recurring),
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Due date and priority row
                if (task.dueAt != null || task.priority != Priority.P4 || task.workflowState == WorkflowState.DOING) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(top = 4.dp)
                    ) {
                        // Due date
                        task.dueAt?.let { dueAt ->
                            val isOverdue = dueAt < System.currentTimeMillis() && !isCompleted
                            Text(
                                text = formatDueDate(dueAt),
                                style = MaterialTheme.typography.bodySmall,
                                color = if (isOverdue) {
                                    MaterialTheme.colorScheme.error
                                } else {
                                    MaterialTheme.colorScheme.onSurfaceVariant
                                }
                            )
                        }

                        // Priority badge (only show if not default P4)
                        if (task.priority != Priority.P4) {
                            PriorityBadge(priority = task.priority)
                        }

                        // Workflow state (only show if DOING)
                        if (task.workflowState == WorkflowState.DOING) {
                            WorkflowStateBadge(state = task.workflowState)
                        }
                    }
                }
            }
        }
    }
}

/**
 * Workflow state badge
 */
@Composable
private fun WorkflowStateBadge(
    state: WorkflowState,
    modifier: Modifier = Modifier
) {
    val (backgroundColor, textColor, label) = when (state) {
        WorkflowState.DOING -> Triple(
            MaterialTheme.colorScheme.primaryContainer,
            MaterialTheme.colorScheme.onPrimaryContainer,
            stringResource(R.string.workflow_doing)
        )
        WorkflowState.TODO -> Triple(
            MaterialTheme.colorScheme.surfaceVariant,
            MaterialTheme.colorScheme.onSurfaceVariant,
            stringResource(R.string.workflow_todo)
        )
        WorkflowState.DONE -> Triple(
            MaterialTheme.colorScheme.secondaryContainer,
            MaterialTheme.colorScheme.onSecondaryContainer,
            stringResource(R.string.workflow_done)
        )
    }

    Surface(
        color = backgroundColor,
        shape = MaterialTheme.shapes.small,
        modifier = modifier
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = textColor,
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
        )
    }
}

/**
 * Format due date for display
 */
private fun formatDueDate(millis: Long): String {
    val now = System.currentTimeMillis()
    val today = getStartOfDay(now)
    val tomorrow = today + 24 * 60 * 60 * 1000
    val dueDay = getStartOfDay(millis)

    return when {
        dueDay < today -> SimpleDateFormat("M/d", Locale.getDefault()).format(Date(millis))
        dueDay == today -> "Today"
        dueDay == tomorrow -> "Tomorrow"
        dueDay < today + 7 * 24 * 60 * 60 * 1000 -> {
            SimpleDateFormat("EEE", Locale.getDefault()).format(Date(millis))
        }
        else -> SimpleDateFormat("M/d", Locale.getDefault()).format(Date(millis))
    }
}

private fun getStartOfDay(millis: Long): Long {
    val calendar = java.util.Calendar.getInstance()
    calendar.timeInMillis = millis
    calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
    calendar.set(java.util.Calendar.MINUTE, 0)
    calendar.set(java.util.Calendar.SECOND, 0)
    calendar.set(java.util.Calendar.MILLISECOND, 0)
    return calendar.timeInMillis
}

@Preview(showBackground = true)
@Composable
private fun TaskRowPreview() {
    LivePlanTheme {
        Column {
            TaskRow(
                task = Task(
                    projectId = "1",
                    title = "Complete the UI implementation",
                    priority = Priority.P1,
                    dueAt = System.currentTimeMillis() + 24 * 60 * 60 * 1000
                ),
                isCompleted = false,
                onToggleComplete = {},
                onClick = {}
            )
            TaskRow(
                task = Task(
                    projectId = "1",
                    title = "Review pull request",
                    priority = Priority.P2,
                    workflowState = WorkflowState.DOING
                ),
                isCompleted = false,
                onToggleComplete = {},
                onClick = {}
            )
            TaskRow(
                task = Task(
                    projectId = "1",
                    title = "Completed task example",
                    priority = Priority.P4
                ),
                isCompleted = true,
                onToggleComplete = {},
                onClick = {}
            )
        }
    }
}
