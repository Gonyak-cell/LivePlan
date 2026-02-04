package com.liveplan.ui.project

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.liveplan.R
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Project
import com.liveplan.core.model.Task
import com.liveplan.core.model.ViewType
import com.liveplan.ui.common.EmptyTasksState
import com.liveplan.ui.common.FullScreenLoading
import com.liveplan.ui.common.GenericErrorState
import com.liveplan.ui.common.NotFoundState
import com.liveplan.shortcuts.notification.LivePlanNotificationService
import com.liveplan.ui.common.TaskRow
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.ProjectDetailEvent
import com.liveplan.viewmodel.ProjectDetailUiState
import com.liveplan.viewmodel.ProjectDetailViewModel
import com.liveplan.viewmodel.TaskItem

/**
 * Project detail screen showing tasks in list view
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProjectDetailScreen(
    projectId: String,
    onNavigateBack: () -> Unit,
    onNavigateToTaskCreate: () -> Unit,
    onNavigateToTaskDetail: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ProjectDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val viewType by viewModel.viewType.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current

    var showDeleteDialog by remember { mutableStateOf(false) }
    var showMenu by remember { mutableStateOf(false) }

    // Handle events
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is ProjectDetailEvent.ProjectDeleted -> {
                    onNavigateBack()
                }
                is ProjectDetailEvent.TaskStarted -> {
                    LivePlanNotificationService.start(context)
                    snackbarHostState.showSnackbar(context.getString(R.string.task_started_notification))
                }
                is ProjectDetailEvent.ShowError -> {
                    snackbarHostState.showSnackbar(event.message)
                }
            }
        }
    }

    when (val state = uiState) {
        is ProjectDetailUiState.Loading -> {
            FullScreenLoading()
        }
        is ProjectDetailUiState.NotFound -> {
            NotFoundState(
                itemType = "Project",
                onNavigateBack = onNavigateBack
            )
        }
        is ProjectDetailUiState.Error -> {
            GenericErrorState(onRetry = { viewModel.retry() })
        }
        is ProjectDetailUiState.Success -> {
            Scaffold(
                topBar = {
                    TopAppBar(
                        title = {
                            Column {
                                Text(
                                    text = state.project.title,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Text(
                                    text = stringResource(
                                        R.string.project_outstanding_count,
                                        state.outstandingCount
                                    ),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        },
                        navigationIcon = {
                            IconButton(onClick = onNavigateBack) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = stringResource(R.string.action_back)
                                )
                            }
                        },
                        actions = {
                            Box {
                                IconButton(onClick = { showMenu = true }) {
                                    Icon(
                                        imageVector = Icons.Default.MoreVert,
                                        contentDescription = "More options"
                                    )
                                }
                                DropdownMenu(
                                    expanded = showMenu,
                                    onDismissRequest = { showMenu = false }
                                ) {
                                    DropdownMenuItem(
                                        text = { Text(stringResource(R.string.action_delete)) },
                                        onClick = {
                                            showMenu = false
                                            showDeleteDialog = true
                                        },
                                        leadingIcon = {
                                            Icon(
                                                imageVector = Icons.Default.Delete,
                                                contentDescription = null
                                            )
                                        }
                                    )
                                }
                            }
                        }
                    )
                },
                floatingActionButton = {
                    FloatingActionButton(
                        onClick = onNavigateToTaskCreate
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = stringResource(R.string.action_add_task)
                        )
                    }
                },
                snackbarHost = { SnackbarHost(snackbarHostState) },
                modifier = modifier
            ) { paddingValues ->
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                ) {
                    // View type tabs
                    ViewTypeTabs(
                        selectedViewType = viewType,
                        onViewTypeSelected = { viewModel.setViewType(it) }
                    )

                    HorizontalDivider()

                    // Content based on view type
                    when (viewType) {
                        ViewType.LIST -> {
                            if (state.tasks.isEmpty()) {
                                EmptyTasksState(onCreateTask = onNavigateToTaskCreate)
                            } else {
                                TaskListView(
                                    tasks = state.tasks,
                                    onTaskClick = { onNavigateToTaskDetail(it.task.id) },
                                    onToggleComplete = { task ->
                                        viewModel.toggleTaskComplete(task.task.id, task.isCompleted)
                                    }
                                )
                            }
                        }
                        ViewType.BOARD -> {
                            if (state.tasks.isEmpty()) {
                                EmptyTasksState(onCreateTask = onNavigateToTaskCreate)
                            } else {
                                KanbanBoardScreen(
                                    tasks = state.tasks,
                                    onTaskClick = { onNavigateToTaskDetail(it.task.id) },
                                    onToggleComplete = { task ->
                                        viewModel.toggleTaskComplete(task.task.id, task.isCompleted)
                                    }
                                )
                            }
                        }
                        ViewType.CALENDAR -> {
                            if (state.tasks.isEmpty()) {
                                EmptyTasksState(onCreateTask = onNavigateToTaskCreate)
                            } else {
                                CalendarScreen(
                                    tasks = state.tasks,
                                    onTaskClick = { onNavigateToTaskDetail(it.task.id) },
                                    onToggleComplete = { task ->
                                        viewModel.toggleTaskComplete(task.task.id, task.isCompleted)
                                    }
                                )
                            }
                        }
                    }
                }
            }

            // Delete confirmation dialog
            if (showDeleteDialog) {
                AlertDialog(
                    onDismissRequest = { showDeleteDialog = false },
                    title = { Text(stringResource(R.string.dialog_delete_title)) },
                    text = {
                        Text("Are you sure you want to delete this project? All tasks will be removed.")
                    },
                    confirmButton = {
                        TextButton(
                            onClick = {
                                showDeleteDialog = false
                                viewModel.deleteProject()
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
private fun ViewTypeTabs(
    selectedViewType: ViewType,
    onViewTypeSelected: (ViewType) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        ViewType.entries.forEach { viewType ->
            FilterChip(
                selected = selectedViewType == viewType,
                onClick = { onViewTypeSelected(viewType) },
                label = {
                    Text(
                        when (viewType) {
                            ViewType.LIST -> stringResource(R.string.view_list)
                            ViewType.BOARD -> stringResource(R.string.view_board)
                            ViewType.CALENDAR -> stringResource(R.string.view_calendar)
                        }
                    )
                }
            )
        }
    }
}

@Composable
private fun TaskListView(
    tasks: List<TaskItem>,
    onTaskClick: (TaskItem) -> Unit,
    onToggleComplete: (TaskItem) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        items(
            items = tasks,
            key = { it.task.id }
        ) { taskItem ->
            TaskRow(
                task = taskItem.task,
                isCompleted = taskItem.isCompleted,
                onToggleComplete = { onToggleComplete(taskItem) },
                onClick = { onTaskClick(taskItem) }
            )
            HorizontalDivider(modifier = Modifier.padding(start = 56.dp))
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun ProjectDetailScreenPreview() {
    LivePlanTheme {
        val tasks = listOf(
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Complete the UI implementation",
                    priority = Priority.P1,
                    dueAt = System.currentTimeMillis() + 24 * 60 * 60 * 1000
                ),
                isCompleted = false,
                section = null
            ),
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Review pull request",
                    priority = Priority.P2
                ),
                isCompleted = false,
                section = null
            ),
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Completed task example",
                    priority = Priority.P4
                ),
                isCompleted = true,
                section = null
            )
        )

        TaskListView(
            tasks = tasks,
            onTaskClick = {},
            onToggleComplete = {}
        )
    }
}
