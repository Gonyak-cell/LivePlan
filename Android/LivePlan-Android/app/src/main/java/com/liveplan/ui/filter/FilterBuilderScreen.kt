package com.liveplan.ui.filter

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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Checkbox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.liveplan.R
import com.liveplan.core.model.DueRange
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Project
import com.liveplan.core.model.Tag
import com.liveplan.core.model.WorkflowState
import com.liveplan.ui.common.FullScreenLoading
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.FilterBuilderEvent
import com.liveplan.viewmodel.FilterBuilderUiState
import com.liveplan.viewmodel.FilterBuilderViewModel

/**
 * Filter builder screen for creating/editing custom filters
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FilterBuilderScreen(
    filterId: String?,
    onNavigateBack: () -> Unit,
    onFilterSaved: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: FilterBuilderViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(filterId) {
        if (filterId != null) {
            viewModel.loadFilter(filterId)
        }
    }

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is FilterBuilderEvent.FilterSaved -> {
                    onFilterSaved()
                }
                is FilterBuilderEvent.ShowError -> {
                    snackbarHostState.showSnackbar(event.message)
                }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        if (filterId == null) {
                            stringResource(R.string.filter_create_title)
                        } else {
                            stringResource(R.string.filter_edit_title)
                        }
                    )
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
                    IconButton(
                        onClick = { viewModel.saveFilter() },
                        enabled = uiState is FilterBuilderUiState.Success &&
                                (uiState as FilterBuilderUiState.Success).name.isNotBlank()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = stringResource(R.string.action_save)
                        )
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
        modifier = modifier
    ) { paddingValues ->
        when (val state = uiState) {
            is FilterBuilderUiState.Loading -> {
                FullScreenLoading()
            }
            is FilterBuilderUiState.Success -> {
                FilterBuilderContent(
                    state = state,
                    onNameChange = { viewModel.setName(it) },
                    onProjectToggle = { viewModel.toggleProject(it) },
                    onTagToggle = { viewModel.toggleTag(it) },
                    onPriorityToggle = { viewModel.togglePriority(it) },
                    onStateToggle = { viewModel.toggleState(it) },
                    onDueRangeChange = { viewModel.setDueRange(it) },
                    onIncludeRecurringChange = { viewModel.setIncludeRecurring(it) },
                    onExcludeBlockedChange = { viewModel.setExcludeBlocked(it) },
                    modifier = Modifier.padding(paddingValues)
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun FilterBuilderContent(
    state: FilterBuilderUiState.Success,
    onNameChange: (String) -> Unit,
    onProjectToggle: (String) -> Unit,
    onTagToggle: (String) -> Unit,
    onPriorityToggle: (Priority) -> Unit,
    onStateToggle: (WorkflowState) -> Unit,
    onDueRangeChange: (DueRange) -> Unit,
    onIncludeRecurringChange: (Boolean) -> Unit,
    onExcludeBlockedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Filter name
        OutlinedTextField(
            value = state.name,
            onValueChange = onNameChange,
            label = { Text(stringResource(R.string.filter_name_label)) },
            placeholder = { Text(stringResource(R.string.filter_name_placeholder)) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        HorizontalDivider()

        // Projects section
        if (state.availableProjects.isNotEmpty()) {
            SectionHeader(title = stringResource(R.string.filter_projects_section))
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                state.availableProjects.forEach { project ->
                    FilterChip(
                        selected = project.id in state.selectedProjects,
                        onClick = { onProjectToggle(project.id) },
                        label = { Text(project.title) }
                    )
                }
            }
        }

        // Tags section
        if (state.availableTags.isNotEmpty()) {
            SectionHeader(title = stringResource(R.string.filter_tags_section))
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                state.availableTags.forEach { tag ->
                    FilterChip(
                        selected = tag.id in state.selectedTags,
                        onClick = { onTagToggle(tag.id) },
                        label = { Text(tag.name) }
                    )
                }
            }
        }

        HorizontalDivider()

        // Priority section
        SectionHeader(title = stringResource(R.string.filter_priority_section))
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Priority.entries.forEach { priority ->
                FilterChip(
                    selected = priority in state.selectedPriorities,
                    onClick = { onPriorityToggle(priority) },
                    label = { Text(priority.name) }
                )
            }
        }

        HorizontalDivider()

        // State section
        SectionHeader(title = stringResource(R.string.filter_state_section))
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            WorkflowState.entries.forEach { workflowState ->
                FilterChip(
                    selected = workflowState in state.selectedStates,
                    onClick = { onStateToggle(workflowState) },
                    label = {
                        Text(
                            when (workflowState) {
                                WorkflowState.TODO -> stringResource(R.string.workflow_todo)
                                WorkflowState.DOING -> stringResource(R.string.workflow_doing)
                                WorkflowState.DONE -> stringResource(R.string.workflow_done)
                            }
                        )
                    }
                )
            }
        }

        HorizontalDivider()

        // Due range section
        SectionHeader(title = stringResource(R.string.filter_due_section))
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            DueRange.entries.forEach { dueRange ->
                FilterChip(
                    selected = state.dueRange == dueRange,
                    onClick = { onDueRangeChange(dueRange) },
                    label = {
                        Text(
                            when (dueRange) {
                                DueRange.TODAY -> stringResource(R.string.filter_today)
                                DueRange.NEXT_7_DAYS -> stringResource(R.string.filter_upcoming)
                                DueRange.OVERDUE -> stringResource(R.string.filter_overdue)
                                DueRange.NONE -> "All"
                            }
                        )
                    }
                )
            }
        }

        HorizontalDivider()

        // Options section
        SectionHeader(title = stringResource(R.string.filter_options_section))

        SwitchOption(
            title = stringResource(R.string.filter_include_recurring),
            checked = state.includeRecurring,
            onCheckedChange = onIncludeRecurringChange
        )

        SwitchOption(
            title = stringResource(R.string.filter_exclude_blocked),
            checked = state.excludeBlocked,
            onCheckedChange = onExcludeBlockedChange
        )

        Spacer(modifier = Modifier.height(32.dp))
    }
}

@Composable
private fun SectionHeader(
    title: String,
    modifier: Modifier = Modifier
) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.primary,
        modifier = modifier
    )
}

@Composable
private fun SwitchOption(
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onCheckedChange(!checked) }
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.bodyMedium
        )
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun FilterBuilderContentPreview() {
    LivePlanTheme {
        FilterBuilderContent(
            state = FilterBuilderUiState.Success(
                name = "My Filter",
                availableProjects = listOf(
                    Project(title = "Work", startDate = System.currentTimeMillis()),
                    Project(title = "Personal", startDate = System.currentTimeMillis())
                ),
                selectedProjects = setOf(),
                availableTags = listOf(
                    Tag(name = "urgent"),
                    Tag(name = "bug")
                ),
                selectedTags = setOf(),
                selectedPriorities = setOf(Priority.P1, Priority.P2),
                selectedStates = setOf(WorkflowState.TODO, WorkflowState.DOING),
                dueRange = DueRange.NONE,
                includeRecurring = true,
                excludeBlocked = true
            ),
            onNameChange = {},
            onProjectToggle = {},
            onTagToggle = {},
            onPriorityToggle = {},
            onStateToggle = {},
            onDueRangeChange = {},
            onIncludeRecurringChange = {},
            onExcludeBlockedChange = {}
        )
    }
}
