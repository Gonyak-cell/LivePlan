package com.liveplan.ui.project

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.liveplan.R
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import com.liveplan.ui.common.PriorityBadge
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.TaskItem
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Kanban board view for tasks
 * Shows TODO/DOING/DONE columns with task cards
 */
@Composable
fun KanbanBoardScreen(
    tasks: List<TaskItem>,
    onTaskClick: (TaskItem) -> Unit,
    onToggleComplete: (TaskItem) -> Unit,
    modifier: Modifier = Modifier
) {
    val todoTasks = tasks.filter { !it.isCompleted && it.task.workflowState == WorkflowState.TODO }
    val doingTasks = tasks.filter { !it.isCompleted && it.task.workflowState == WorkflowState.DOING }
    val doneTasks = tasks.filter { it.isCompleted || it.task.workflowState == WorkflowState.DONE }

    LazyRow(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            KanbanColumn(
                title = stringResource(R.string.board_column_todo),
                tasks = todoTasks,
                columnColor = MaterialTheme.colorScheme.primaryContainer,
                onTaskClick = onTaskClick,
                onToggleComplete = onToggleComplete
            )
        }
        item {
            KanbanColumn(
                title = stringResource(R.string.board_column_doing),
                tasks = doingTasks,
                columnColor = MaterialTheme.colorScheme.secondaryContainer,
                onTaskClick = onTaskClick,
                onToggleComplete = onToggleComplete
            )
        }
        item {
            KanbanColumn(
                title = stringResource(R.string.board_column_done),
                tasks = doneTasks,
                columnColor = MaterialTheme.colorScheme.tertiaryContainer,
                onTaskClick = onTaskClick,
                onToggleComplete = onToggleComplete
            )
        }
    }
}

@Composable
private fun KanbanColumn(
    title: String,
    tasks: List<TaskItem>,
    columnColor: Color,
    onTaskClick: (TaskItem) -> Unit,
    onToggleComplete: (TaskItem) -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier
            .width(280.dp)
            .fillMaxHeight(),
        shape = RoundedCornerShape(12.dp),
        color = columnColor.copy(alpha = 0.3f)
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            // Column header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = columnColor
                ) {
                    Text(
                        text = tasks.size.toString(),
                        style = MaterialTheme.typography.labelMedium,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }

            // Tasks list
            if (tasks.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = stringResource(R.string.board_empty_column),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            } else {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(
                        items = tasks,
                        key = { it.task.id }
                    ) { taskItem ->
                        KanbanTaskCard(
                            taskItem = taskItem,
                            onClick = { onTaskClick(taskItem) },
                            onToggleComplete = { onToggleComplete(taskItem) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun KanbanTaskCard(
    taskItem: TaskItem,
    onClick: () -> Unit,
    onToggleComplete: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            // Title row with completion toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.Top
            ) {
                Icon(
                    imageVector = if (taskItem.isCompleted) {
                        Icons.Default.CheckCircle
                    } else {
                        Icons.Default.Circle
                    },
                    contentDescription = if (taskItem.isCompleted) {
                        stringResource(R.string.task_uncomplete)
                    } else {
                        stringResource(R.string.task_complete)
                    },
                    modifier = Modifier
                        .size(20.dp)
                        .clickable(onClick = onToggleComplete),
                    tint = if (taskItem.isCompleted) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    }
                )

                Text(
                    text = taskItem.task.title,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
            }

            // Metadata row
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Priority badge
                if (taskItem.task.priority != Priority.P4) {
                    PriorityBadge(priority = taskItem.task.priority)
                }

                // Due date
                taskItem.task.dueAt?.let { dueAt ->
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Schedule,
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = if (dueAt < System.currentTimeMillis()) {
                                MaterialTheme.colorScheme.error
                            } else {
                                MaterialTheme.colorScheme.onSurfaceVariant
                            }
                        )
                        Text(
                            text = formatDueDate(dueAt),
                            style = MaterialTheme.typography.labelSmall,
                            color = if (dueAt < System.currentTimeMillis()) {
                                MaterialTheme.colorScheme.error
                            } else {
                                MaterialTheme.colorScheme.onSurfaceVariant
                            }
                        )
                    }
                }

                // Recurring indicator
                if (taskItem.task.isRecurring) {
                    Text(
                        text = stringResource(R.string.task_recurring),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

private fun formatDueDate(timestamp: Long): String {
    val dateFormat = SimpleDateFormat("MMM d", Locale.getDefault())
    return dateFormat.format(Date(timestamp))
}

@Preview(showBackground = true)
@Composable
private fun KanbanBoardScreenPreview() {
    LivePlanTheme {
        val tasks = listOf(
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Design new feature",
                    priority = Priority.P1,
                    workflowState = WorkflowState.TODO,
                    dueAt = System.currentTimeMillis() + 24 * 60 * 60 * 1000
                ),
                isCompleted = false,
                section = null
            ),
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Implement API endpoint",
                    priority = Priority.P2,
                    workflowState = WorkflowState.TODO
                ),
                isCompleted = false,
                section = null
            ),
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Code review",
                    priority = Priority.P2,
                    workflowState = WorkflowState.DOING
                ),
                isCompleted = false,
                section = null
            ),
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Write documentation",
                    priority = Priority.P4,
                    workflowState = WorkflowState.DONE
                ),
                isCompleted = true,
                section = null
            )
        )

        KanbanBoardScreen(
            tasks = tasks,
            onTaskClick = {},
            onToggleComplete = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun KanbanColumnPreview() {
    LivePlanTheme {
        KanbanColumn(
            title = "To Do",
            tasks = listOf(
                TaskItem(
                    task = Task(
                        projectId = "1",
                        title = "Sample task",
                        priority = Priority.P1
                    ),
                    isCompleted = false,
                    section = null
                )
            ),
            columnColor = MaterialTheme.colorScheme.primaryContainer,
            onTaskClick = {},
            onToggleComplete = {},
            modifier = Modifier.height(400.dp)
        )
    }
}
