package com.liveplan.ui.project

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.liveplan.R
import com.liveplan.core.model.Project
import com.liveplan.ui.common.EmptyProjectsState
import com.liveplan.ui.common.FullScreenLoading
import com.liveplan.ui.common.GenericErrorState
import com.liveplan.ui.common.ProjectCard
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.ProjectListEvent
import com.liveplan.viewmodel.ProjectListItem
import com.liveplan.viewmodel.ProjectListUiState
import com.liveplan.viewmodel.ProjectListViewModel

/**
 * Project list screen (home screen)
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProjectListScreen(
    onNavigateToProject: (String) -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToSearch: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ProjectListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val showCreateDialog by viewModel.showCreateDialog.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    // Handle events
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is ProjectListEvent.ProjectCreated -> {
                    onNavigateToProject(event.projectId)
                }
                is ProjectListEvent.ShowError -> {
                    snackbarHostState.showSnackbar(event.message)
                }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.projects_title)) },
                actions = {
                    IconButton(onClick = onNavigateToSearch) {
                        Icon(
                            imageVector = Icons.Default.Search,
                            contentDescription = stringResource(R.string.search_title)
                        )
                    }
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(
                            imageVector = Icons.Default.Settings,
                            contentDescription = stringResource(R.string.settings_title)
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { viewModel.showCreateProjectDialog() }
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = stringResource(R.string.action_create_project)
                )
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
        modifier = modifier
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when (val state = uiState) {
                is ProjectListUiState.Loading -> {
                    FullScreenLoading()
                }
                is ProjectListUiState.Error -> {
                    GenericErrorState(onRetry = { viewModel.retry() })
                }
                is ProjectListUiState.Success -> {
                    if (state.projects.isEmpty()) {
                        EmptyProjectsState(
                            onCreateProject = { viewModel.showCreateProjectDialog() }
                        )
                    } else {
                        ProjectList(
                            projects = state.projects,
                            onProjectClick = onNavigateToProject
                        )
                    }
                }
            }
        }
    }

    // Create Project Dialog
    if (showCreateDialog) {
        CreateProjectDialog(
            onDismiss = { viewModel.dismissCreateProjectDialog() },
            onCreate = { title, startDate, dueDate, note ->
                viewModel.createProject(title, startDate, dueDate, note)
            }
        )
    }
}

@Composable
private fun ProjectList(
    projects: List<ProjectListItem>,
    onProjectClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(
            items = projects,
            key = { it.project.id }
        ) { item ->
            ProjectCard(
                project = item.project,
                taskCount = item.taskCount,
                completedCount = item.completedCount,
                isPinned = item.isPinned,
                onClick = { onProjectClick(item.project.id) }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CreateProjectDialog(
    onDismiss: () -> Unit,
    onCreate: (title: String, startDate: Long, dueDate: Long?, note: String?) -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    var title by rememberSaveable { mutableStateOf("") }
    var startDate by rememberSaveable { mutableStateOf(System.currentTimeMillis()) }
    var dueDate by rememberSaveable { mutableStateOf<Long?>(null) }
    var note by rememberSaveable { mutableStateOf("") }

    var showStartDatePicker by remember { mutableStateOf(false) }
    var showDueDatePicker by remember { mutableStateOf(false) }

    var titleError by remember { mutableStateOf<String?>(null) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp)
        ) {
            Text(
                text = stringResource(R.string.action_create_project),
                style = MaterialTheme.typography.headlineSmall
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Title field
            OutlinedTextField(
                value = title,
                onValueChange = {
                    title = it
                    titleError = null
                },
                label = { Text(stringResource(R.string.project_title_label)) },
                placeholder = { Text(stringResource(R.string.project_title_placeholder)) },
                isError = titleError != null,
                supportingText = titleError?.let { { Text(it) } },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Start date
            OutlinedTextField(
                value = formatDateForDisplay(startDate),
                onValueChange = {},
                label = { Text(stringResource(R.string.project_start_date_label)) },
                readOnly = true,
                modifier = Modifier.fillMaxWidth(),
                trailingIcon = {
                    TextButton(onClick = { showStartDatePicker = true }) {
                        Text(stringResource(R.string.date_select))
                    }
                }
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Due date (optional)
            OutlinedTextField(
                value = dueDate?.let { formatDateForDisplay(it) } ?: "",
                onValueChange = {},
                label = { Text(stringResource(R.string.project_due_date_label)) },
                readOnly = true,
                modifier = Modifier.fillMaxWidth(),
                trailingIcon = {
                    TextButton(onClick = { showDueDatePicker = true }) {
                        Text(stringResource(R.string.date_select))
                    }
                }
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Note (optional)
            OutlinedTextField(
                value = note,
                onValueChange = { note = it },
                label = { Text(stringResource(R.string.project_note_label)) },
                placeholder = { Text(stringResource(R.string.project_note_placeholder)) },
                minLines = 3,
                maxLines = 5,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Action buttons
            androidx.compose.foundation.layout.Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                TextButton(onClick = onDismiss) {
                    Text(stringResource(R.string.action_cancel))
                }
                TextButton(
                    onClick = {
                        if (title.isBlank()) {
                            titleError = "Title is required"
                        } else {
                            onCreate(
                                title.trim(),
                                startDate,
                                dueDate,
                                note.takeIf { it.isNotBlank() }
                            )
                        }
                    }
                ) {
                    Text(stringResource(R.string.action_save))
                }
            }
        }
    }

    // Date pickers
    if (showStartDatePicker) {
        DatePickerDialogWrapper(
            initialDate = startDate,
            onDateSelected = {
                startDate = it
                showStartDatePicker = false
            },
            onDismiss = { showStartDatePicker = false }
        )
    }

    if (showDueDatePicker) {
        DatePickerDialogWrapper(
            initialDate = dueDate ?: System.currentTimeMillis(),
            onDateSelected = {
                dueDate = it
                showDueDatePicker = false
            },
            onDismiss = { showDueDatePicker = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DatePickerDialogWrapper(
    initialDate: Long,
    onDateSelected: (Long) -> Unit,
    onDismiss: () -> Unit
) {
    val datePickerState = rememberDatePickerState(initialSelectedDateMillis = initialDate)

    DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(
                onClick = {
                    datePickerState.selectedDateMillis?.let { onDateSelected(it) }
                }
            ) {
                Text(stringResource(R.string.action_confirm))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.action_cancel))
            }
        }
    ) {
        DatePicker(state = datePickerState)
    }
}

private fun formatDateForDisplay(millis: Long): String {
    val formatter = java.text.SimpleDateFormat("MMM d, yyyy", java.util.Locale.getDefault())
    return formatter.format(java.util.Date(millis))
}

@Preview(showBackground = true)
@Composable
private fun ProjectListScreenPreview() {
    LivePlanTheme {
        // Preview with mock data
        ProjectList(
            projects = listOf(
                ProjectListItem(
                    project = Project(
                        title = "LivePlan Development",
                        startDate = System.currentTimeMillis()
                    ),
                    taskCount = 10,
                    completedCount = 3,
                    isPinned = true
                ),
                ProjectListItem(
                    project = Project(
                        title = "Personal Tasks",
                        startDate = System.currentTimeMillis()
                    ),
                    taskCount = 5,
                    completedCount = 5,
                    isPinned = false
                )
            ),
            onProjectClick = {}
        )
    }
}
