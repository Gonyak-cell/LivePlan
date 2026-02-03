package com.liveplan.ui.task

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.liveplan.R
import com.liveplan.core.model.Priority
import com.liveplan.core.model.RecurrenceKind
import com.liveplan.core.model.Section
import com.liveplan.core.model.Tag
import com.liveplan.ui.common.PriorityBadge
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.TaskCreateEvent
import com.liveplan.viewmodel.TaskCreateUiState
import com.liveplan.viewmodel.TaskCreateViewModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Task create screen
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun TaskCreateScreen(
    projectId: String,
    onNavigateBack: () -> Unit,
    onTaskCreated: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: TaskCreateViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val focusRequester = remember { FocusRequester() }

    // Form state
    var title by rememberSaveable { mutableStateOf("") }
    var priority by rememberSaveable { mutableStateOf(Priority.P4) }
    var dueDate by rememberSaveable { mutableStateOf<Long?>(null) }
    var recurrenceKind by rememberSaveable { mutableStateOf<RecurrenceKind?>(null) }
    var selectedSectionId by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedTagIds by rememberSaveable { mutableStateOf<Set<String>>(emptySet()) }
    var note by rememberSaveable { mutableStateOf("") }

    var showDatePicker by remember { mutableStateOf(false) }
    var titleError by remember { mutableStateOf<String?>(null) }

    // Handle events
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is TaskCreateEvent.TaskCreated -> {
                    onTaskCreated()
                }
                is TaskCreateEvent.ShowError -> {
                    snackbarHostState.showSnackbar(event.message)
                }
            }
        }
    }

    // Focus title field on launch
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.task_create_title)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.action_back)
                        )
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            if (title.isBlank()) {
                                titleError = "Title is required"
                            } else {
                                viewModel.createTask(
                                    title = title.trim(),
                                    priority = priority,
                                    dueAt = dueDate,
                                    recurrenceKind = recurrenceKind,
                                    sectionId = selectedSectionId,
                                    tagIds = selectedTagIds.toList(),
                                    note = note.takeIf { it.isNotBlank() }
                                )
                            }
                        },
                        enabled = uiState !is TaskCreateUiState.Saving
                    ) {
                        Text(stringResource(R.string.action_save))
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
                .imePadding()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Title field
            OutlinedTextField(
                value = title,
                onValueChange = {
                    title = it
                    titleError = null
                },
                label = { Text(stringResource(R.string.task_title_label)) },
                placeholder = { Text(stringResource(R.string.task_title_placeholder)) },
                isError = titleError != null,
                supportingText = titleError?.let { { Text(it) } },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(focusRequester)
            )

            // Priority selection
            Text(
                text = stringResource(R.string.task_priority_label),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Priority.entries.forEach { p ->
                    FilterChip(
                        selected = priority == p,
                        onClick = { priority = p },
                        label = { PriorityBadge(priority = p) }
                    )
                }
            }

            // Due date
            OutlinedTextField(
                value = dueDate?.let { formatDateForDisplay(it) } ?: "",
                onValueChange = {},
                label = { Text(stringResource(R.string.task_due_date_label)) },
                readOnly = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { showDatePicker = true },
                trailingIcon = {
                    Row {
                        if (dueDate != null) {
                            TextButton(onClick = { dueDate = null }) {
                                Text(stringResource(R.string.action_clear))
                            }
                        }
                        IconButton(onClick = { showDatePicker = true }) {
                            Icon(
                                imageVector = Icons.Default.CalendarToday,
                                contentDescription = stringResource(R.string.date_select)
                            )
                        }
                    }
                }
            )

            // Recurrence selection
            Text(
                text = stringResource(R.string.task_recurrence_label),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                FilterChip(
                    selected = recurrenceKind == null,
                    onClick = { recurrenceKind = null },
                    label = { Text(stringResource(R.string.task_recurrence_none)) }
                )
                RecurrenceKind.entries.forEach { kind ->
                    FilterChip(
                        selected = recurrenceKind == kind,
                        onClick = { recurrenceKind = kind },
                        label = {
                            Text(
                                when (kind) {
                                    RecurrenceKind.DAILY -> stringResource(R.string.task_recurrence_daily)
                                    RecurrenceKind.WEEKLY -> stringResource(R.string.task_recurrence_weekly)
                                    RecurrenceKind.MONTHLY -> stringResource(R.string.task_recurrence_monthly)
                                }
                            )
                        }
                    )
                }
            }

            // Section selection (if sections available)
            val state = uiState
            if (state is TaskCreateUiState.Ready && state.sections.isNotEmpty()) {
                SectionDropdown(
                    sections = state.sections,
                    selectedSectionId = selectedSectionId,
                    onSectionSelected = { selectedSectionId = it }
                )
            }

            // Tags selection (if tags available)
            if (state is TaskCreateUiState.Ready && state.tags.isNotEmpty()) {
                Text(
                    text = stringResource(R.string.task_tags_label),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    state.tags.forEach { tag ->
                        FilterChip(
                            selected = tag.id in selectedTagIds,
                            onClick = {
                                selectedTagIds = if (tag.id in selectedTagIds) {
                                    selectedTagIds - tag.id
                                } else {
                                    selectedTagIds + tag.id
                                }
                            },
                            label = { Text(tag.name) }
                        )
                    }
                }
            }

            // Note
            OutlinedTextField(
                value = note,
                onValueChange = { note = it },
                label = { Text(stringResource(R.string.task_note_label)) },
                placeholder = { Text(stringResource(R.string.task_note_placeholder)) },
                minLines = 3,
                maxLines = 5,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(32.dp))
        }
    }

    // Date picker dialog
    if (showDatePicker) {
        DatePickerDialogWrapper(
            initialDate = dueDate ?: System.currentTimeMillis(),
            onDateSelected = {
                dueDate = it
                showDatePicker = false
            },
            onDismiss = { showDatePicker = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SectionDropdown(
    sections: List<Section>,
    selectedSectionId: String?,
    onSectionSelected: (String?) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    val selectedSection = sections.find { it.id == selectedSectionId }

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it },
        modifier = modifier
    ) {
        OutlinedTextField(
            value = selectedSection?.title ?: stringResource(R.string.task_section_none),
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.task_section_label)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .fillMaxWidth()
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.task_section_none)) },
                onClick = {
                    onSectionSelected(null)
                    expanded = false
                }
            )
            sections.forEach { section ->
                DropdownMenuItem(
                    text = { Text(section.title) },
                    onClick = {
                        onSectionSelected(section.id)
                        expanded = false
                    }
                )
            }
        }
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
    val formatter = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
    return formatter.format(Date(millis))
}

@Preview(showBackground = true)
@Composable
private fun TaskCreateScreenPreview() {
    LivePlanTheme {
        // Preview without ViewModel - just layout
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            OutlinedTextField(
                value = "",
                onValueChange = {},
                label = { Text("Task Title") },
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
