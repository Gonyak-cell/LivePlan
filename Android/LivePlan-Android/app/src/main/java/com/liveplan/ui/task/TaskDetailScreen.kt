package com.liveplan.ui.task

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.liveplan.R
import com.liveplan.core.model.Priority
import com.liveplan.core.model.RecurrenceKind
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import com.liveplan.ui.common.FullScreenLoading
import com.liveplan.ui.common.GenericErrorState
import com.liveplan.ui.common.NotFoundState
import com.liveplan.ui.common.PriorityBadge
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.TaskDetailEvent
import com.liveplan.viewmodel.TaskDetailUiState
import com.liveplan.viewmodel.TaskDetailViewModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Task detail screen
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun TaskDetailScreen(
    taskId: String,
    onNavigateBack: () -> Unit,
    onTaskDeleted: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: TaskDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    var showDeleteDialog by remember { mutableStateOf(false) }

    // Handle events
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is TaskDetailEvent.TaskDeleted -> {
                    onTaskDeleted()
                }
                is TaskDetailEvent.ShowError -> {
                    snackbarHostState.showSnackbar(event.message)
                }
                is TaskDetailEvent.ShowMessage -> {
                    snackbarHostState.showSnackbar(event.message)
                }
            }
        }
    }

    when (val state = uiState) {
        is TaskDetailUiState.Loading -> {
            FullScreenLoading()
        }
        is TaskDetailUiState.NotFound -> {
            NotFoundState(
                itemType = "Task",
                onNavigateBack = onNavigateBack
            )
        }
        is TaskDetailUiState.Error -> {
            GenericErrorState(onRetry = { viewModel.retry() })
        }
        is TaskDetailUiState.Success -> {
            Scaffold(
                topBar = {
                    TopAppBar(
                        title = { Text(stringResource(R.string.task_detail_title)) },
                        navigationIcon = {
                            IconButton(onClick = onNavigateBack) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = stringResource(R.string.action_back)
                                )
                            }
                        },
                        actions = {
                            IconButton(onClick = { showDeleteDialog = true }) {
                                Icon(
                                    imageVector = Icons.Default.Delete,
                                    contentDescription = stringResource(R.string.action_delete)
                                )
                            }
                        }
                    )
                },
                snackbarHost = { SnackbarHost(snackbarHostState) },
                modifier = modifier
            ) { paddingValues ->
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Task title and status
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                        )
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp)
                        ) {
                            Text(
                                text = state.task.title,
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Medium,
                                textDecoration = if (state.isCompleted) TextDecoration.LineThrough else null,
                                color = if (state.isCompleted) {
                                    MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                } else {
                                    MaterialTheme.colorScheme.onSurface
                                }
                            )

                            Spacer(modifier = Modifier.height(8.dp))

                            // Status chips
                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                // Priority
                                PriorityBadge(priority = state.task.priority)

                                // Workflow state
                                if (state.task.workflowState == WorkflowState.DOING) {
                                    AssistChip(
                                        onClick = {},
                                        label = { Text(stringResource(R.string.workflow_doing)) }
                                    )
                                }

                                // Recurring indicator
                                if (state.task.isRecurring) {
                                    AssistChip(
                                        onClick = {},
                                        leadingIcon = {
                                            Icon(
                                                imageVector = Icons.Default.Refresh,
                                                contentDescription = null,
                                                modifier = Modifier.size(16.dp)
                                            )
                                        },
                                        label = {
                                            Text(
                                                when (state.task.recurrenceRule?.kind) {
                                                    RecurrenceKind.DAILY -> stringResource(R.string.task_recurrence_daily)
                                                    RecurrenceKind.WEEKLY -> stringResource(R.string.task_recurrence_weekly)
                                                    RecurrenceKind.MONTHLY -> stringResource(R.string.task_recurrence_monthly)
                                                    else -> stringResource(R.string.task_recurring)
                                                }
                                            )
                                        }
                                    )
                                }

                                // Completed indicator
                                if (state.isCompleted) {
                                    AssistChip(
                                        onClick = {},
                                        leadingIcon = {
                                            Icon(
                                                imageVector = Icons.Default.Check,
                                                contentDescription = null,
                                                modifier = Modifier.size(16.dp)
                                            )
                                        },
                                        label = { Text(stringResource(R.string.workflow_done)) }
                                    )
                                }
                            }
                        }
                    }

                    // Due date
                    state.task.dueAt?.let { dueAt ->
                        DetailRow(
                            icon = Icons.Default.CalendarToday,
                            label = "Due Date",
                            value = formatDateForDisplay(dueAt)
                        )
                    }

                    // Section
                    state.section?.let { section ->
                        DetailRow(
                            icon = null,
                            label = "Section",
                            value = section.title
                        )
                    }

                    // Tags
                    if (state.tags.isNotEmpty()) {
                        Column {
                            Text(
                                text = "Tags",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                state.tags.forEach { tag ->
                                    AssistChip(
                                        onClick = {},
                                        label = { Text(tag.name) }
                                    )
                                }
                            }
                        }
                    }

                    // Note
                    state.task.note?.let { note ->
                        Column {
                            Text(
                                text = "Note",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = note,
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                    }

                    HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                    // Action buttons
                    Column(
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        // Complete/Uncomplete button
                        Button(
                            onClick = { viewModel.toggleComplete() },
                            modifier = Modifier.fillMaxWidth(),
                            colors = if (state.isCompleted) {
                                ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.secondaryContainer,
                                    contentColor = MaterialTheme.colorScheme.onSecondaryContainer
                                )
                            } else {
                                ButtonDefaults.buttonColors()
                            }
                        ) {
                            Icon(
                                imageVector = if (state.isCompleted) Icons.AutoMirrored.Filled.Undo else Icons.Default.Check,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                if (state.isCompleted) {
                                    stringResource(R.string.task_uncomplete)
                                } else {
                                    stringResource(R.string.task_complete)
                                }
                            )
                        }

                        // Start button (only show if not doing and not completed)
                        if (!state.isCompleted && state.task.workflowState != WorkflowState.DOING) {
                            OutlinedButton(
                                onClick = { viewModel.startTask() },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Icon(
                                    imageVector = Icons.Default.PlayArrow,
                                    contentDescription = null,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(stringResource(R.string.task_start))
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(32.dp))
                }
            }

            // Delete confirmation dialog
            if (showDeleteDialog) {
                AlertDialog(
                    onDismissRequest = { showDeleteDialog = false },
                    title = { Text(stringResource(R.string.task_delete_confirm_title)) },
                    text = { Text(stringResource(R.string.task_delete_confirm_message)) },
                    confirmButton = {
                        TextButton(
                            onClick = {
                                showDeleteDialog = false
                                viewModel.deleteTask()
                            }
                        ) {
                            Text(
                                stringResource(R.string.action_delete),
                                color = MaterialTheme.colorScheme.error
                            )
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { showDeleteDialog = false }) {
                            Text(stringResource(R.string.action_cancel))
                        }
                    }
                )
            }
        }
    }
}

@Composable
private fun DetailRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector?,
    label: String,
    value: String,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.width(12.dp))
        }
        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}

private fun formatDateForDisplay(millis: Long): String {
    val formatter = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
    return formatter.format(Date(millis))
}

@Preview(showBackground = true)
@Composable
private fun TaskDetailScreenPreview() {
    LivePlanTheme {
        // Preview layout only
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Complete the UI implementation",
                style = MaterialTheme.typography.headlineSmall
            )
            PriorityBadge(priority = Priority.P1)
        }
    }
}
