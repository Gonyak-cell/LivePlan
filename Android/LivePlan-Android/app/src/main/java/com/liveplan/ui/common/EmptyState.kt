package com.liveplan.ui.common

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Task
import androidx.compose.material.icons.filled.ViewKanban
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.liveplan.R
import com.liveplan.ui.theme.LivePlanTheme

/**
 * Empty state component with icon, message, and optional CTA button
 */
@Composable
fun EmptyState(
    icon: ImageVector,
    title: String,
    description: String?,
    modifier: Modifier = Modifier,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center
        )

        if (description != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }

        if (actionLabel != null && onAction != null) {
            Spacer(modifier = Modifier.height(24.dp))
            Button(onClick = onAction) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.size(8.dp))
                Text(text = actionLabel)
            }
        }
    }
}

/**
 * Empty state for no projects
 */
@Composable
fun EmptyProjectsState(
    onCreateProject: () -> Unit,
    modifier: Modifier = Modifier
) {
    EmptyState(
        icon = Icons.Default.Folder,
        title = stringResource(R.string.empty_projects_title),
        description = stringResource(R.string.empty_projects_description),
        actionLabel = stringResource(R.string.action_create_project),
        onAction = onCreateProject,
        modifier = modifier
    )
}

/**
 * Empty state for no tasks in a project
 */
@Composable
fun EmptyTasksState(
    onCreateTask: () -> Unit,
    modifier: Modifier = Modifier
) {
    EmptyState(
        icon = Icons.Default.Task,
        title = stringResource(R.string.empty_tasks_title),
        description = stringResource(R.string.empty_tasks_description),
        actionLabel = stringResource(R.string.action_add_task),
        onAction = onCreateTask,
        modifier = modifier
    )
}

/**
 * Empty state for all tasks completed
 */
@Composable
fun AllTasksCompletedState(
    modifier: Modifier = Modifier
) {
    EmptyState(
        icon = Icons.Default.CheckCircle,
        title = stringResource(R.string.all_tasks_completed_title),
        description = stringResource(R.string.all_tasks_completed_description),
        modifier = modifier
    )
}

/**
 * Empty state for search results
 */
@Composable
fun EmptySearchResultsState(
    query: String,
    modifier: Modifier = Modifier
) {
    EmptyState(
        icon = Icons.Default.Search,
        title = stringResource(R.string.search_no_results),
        description = "No results found for \"$query\"",
        modifier = modifier
    )
}

/**
 * Empty state for filter results
 */
@Composable
fun EmptyFilterResultsState(
    modifier: Modifier = Modifier
) {
    EmptyState(
        icon = Icons.Default.FilterList,
        title = stringResource(R.string.filter_no_results),
        description = "Try adjusting your filter criteria",
        modifier = modifier
    )
}

/**
 * Empty state for calendar view (no tasks with due dates)
 */
@Composable
fun EmptyCalendarState(
    onCreateTask: () -> Unit,
    modifier: Modifier = Modifier
) {
    EmptyState(
        icon = Icons.Default.CalendarMonth,
        title = "No Scheduled Tasks",
        description = "Add tasks with due dates to see them on the calendar",
        actionLabel = stringResource(R.string.action_add_task),
        onAction = onCreateTask,
        modifier = modifier
    )
}

/**
 * Empty state for board view columns
 */
@Composable
fun EmptyBoardColumnState(
    columnName: String,
    modifier: Modifier = Modifier
) {
    EmptyState(
        icon = Icons.Default.ViewKanban,
        title = "No tasks in $columnName",
        description = null,
        modifier = modifier
    )
}

@Preview(showBackground = true)
@Composable
private fun EmptyStatePreview() {
    LivePlanTheme {
        Column(verticalArrangement = Arrangement.spacedBy(32.dp)) {
            EmptyProjectsState(onCreateProject = {})
            EmptyTasksState(onCreateTask = {})
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun EmptySearchResultsStatePreview() {
    LivePlanTheme {
        EmptySearchResultsState(query = "test query")
    }
}

@Preview(showBackground = true)
@Composable
private fun EmptyFilterResultsStatePreview() {
    LivePlanTheme {
        EmptyFilterResultsState()
    }
}
