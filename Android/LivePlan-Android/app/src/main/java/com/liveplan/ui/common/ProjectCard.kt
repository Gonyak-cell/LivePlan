package com.liveplan.ui.common

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.liveplan.R
import com.liveplan.core.model.Project
import com.liveplan.core.model.ProjectStatus
import com.liveplan.ui.theme.LivePlanTheme
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Project card component displaying:
 * - Title
 * - Task count summary
 * - Due date (if present)
 * - Pinned indicator (if pinned)
 */
@Composable
fun ProjectCard(
    project: Project,
    taskCount: Int,
    completedCount: Int,
    isPinned: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Title row with pinned indicator
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = project.title,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )

                if (isPinned) {
                    Icon(
                        imageVector = Icons.Default.PushPin,
                        contentDescription = stringResource(R.string.project_pinned),
                        modifier = Modifier.size(18.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Task count summary
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Outstanding count
                val outstandingCount = taskCount - completedCount
                Text(
                    text = stringResource(R.string.project_outstanding_count, outstandingCount),
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (outstandingCount > 0) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    }
                )

                // Completed count
                if (completedCount > 0) {
                    Text(
                        text = stringResource(R.string.project_completed_count, completedCount),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Due date (if present)
            project.dueDate?.let { dueDate ->
                Spacer(modifier = Modifier.height(4.dp))
                val isOverdue = dueDate < System.currentTimeMillis()
                Text(
                    text = stringResource(
                        R.string.project_due_date,
                        formatDate(dueDate)
                    ),
                    style = MaterialTheme.typography.bodySmall,
                    color = if (isOverdue) {
                        MaterialTheme.colorScheme.error
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    }
                )
            }

            // Status indicator for non-active projects
            if (project.status != ProjectStatus.ACTIVE) {
                Spacer(modifier = Modifier.height(4.dp))
                ProjectStatusBadge(status = project.status)
            }
        }
    }
}

/**
 * Project status badge
 */
@Composable
private fun ProjectStatusBadge(
    status: ProjectStatus,
    modifier: Modifier = Modifier
) {
    val (text, color) = when (status) {
        ProjectStatus.ACTIVE -> Pair(
            stringResource(R.string.project_status_active),
            MaterialTheme.colorScheme.primary
        )
        ProjectStatus.ARCHIVED -> Pair(
            stringResource(R.string.project_status_archived),
            MaterialTheme.colorScheme.outline
        )
        ProjectStatus.COMPLETED -> Pair(
            stringResource(R.string.project_status_completed),
            MaterialTheme.colorScheme.tertiary
        )
    }

    Text(
        text = text,
        style = MaterialTheme.typography.labelSmall,
        color = color,
        modifier = modifier
    )
}

private fun formatDate(millis: Long): String {
    return SimpleDateFormat("MMM d, yyyy", Locale.getDefault()).format(Date(millis))
}

@Preview(showBackground = true)
@Composable
private fun ProjectCardPreview() {
    LivePlanTheme {
        Column(
            verticalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.padding(16.dp)
        ) {
            ProjectCard(
                project = Project(
                    title = "LivePlan Android Development",
                    startDate = System.currentTimeMillis(),
                    dueDate = System.currentTimeMillis() + 7 * 24 * 60 * 60 * 1000
                ),
                taskCount = 10,
                completedCount = 3,
                isPinned = true,
                onClick = {}
            )
            ProjectCard(
                project = Project(
                    title = "Personal Tasks",
                    startDate = System.currentTimeMillis()
                ),
                taskCount = 5,
                completedCount = 5,
                isPinned = false,
                onClick = {}
            )
        }
    }
}
