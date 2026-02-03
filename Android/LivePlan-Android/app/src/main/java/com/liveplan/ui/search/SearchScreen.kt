package com.liveplan.ui.search

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.liveplan.R
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Project
import com.liveplan.core.model.Task
import com.liveplan.ui.common.EmptyState
import com.liveplan.ui.common.InlineLoading
import com.liveplan.ui.common.PriorityBadge
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.SearchProjectItem
import com.liveplan.viewmodel.SearchTaskItem
import com.liveplan.viewmodel.SearchUiState
import com.liveplan.viewmodel.SearchViewModel

/**
 * Search screen for projects and tasks
 * Provides local string search across projects, tasks, notes, and tags
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    onNavigateBack: () -> Unit,
    onNavigateToTask: (String) -> Unit,
    onNavigateToProject: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: SearchViewModel = hiltViewModel()
) {
    val query by viewModel.query.collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.search_title)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.action_back)
                        )
                    }
                }
            )
        },
        modifier = modifier
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search input
            SearchInput(
                query = query,
                onQueryChange = { viewModel.setQuery(it) },
                onClear = { viewModel.clearQuery() },
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )

            // Search results
            when (val state = uiState) {
                is SearchUiState.Empty -> {
                    SearchEmptyState()
                }
                is SearchUiState.Loading -> {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(32.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        InlineLoading(modifier = Modifier.size(48.dp))
                    }
                }
                is SearchUiState.NoResults -> {
                    SearchNoResults(query = state.query)
                }
                is SearchUiState.Success -> {
                    SearchResults(
                        projects = state.projects,
                        tasks = state.tasks,
                        onProjectClick = { onNavigateToProject(it.project.id) },
                        onTaskClick = { onNavigateToTask(it.task.id) }
                    )
                }
                is SearchUiState.Error -> {
                    EmptyState(
                        icon = Icons.Default.Search,
                        title = "Search Error",
                        description = state.message
                    )
                }
            }
        }
    }
}

@Composable
private fun SearchInput(
    query: String,
    onQueryChange: (String) -> Unit,
    onClear: () -> Unit,
    modifier: Modifier = Modifier
) {
    TextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = { Text(stringResource(R.string.search_hint)) },
        leadingIcon = {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = onClear) {
                    Icon(
                        imageVector = Icons.Default.Clear,
                        contentDescription = stringResource(R.string.action_clear)
                    )
                }
            }
        },
        singleLine = true,
        colors = TextFieldDefaults.colors(
            focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
            unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
            focusedIndicatorColor = Color.Transparent,
            unfocusedIndicatorColor = Color.Transparent
        ),
        shape = MaterialTheme.shapes.large,
        modifier = modifier.fillMaxWidth()
    )
}

@Composable
private fun SearchEmptyState(
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .padding(32.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = stringResource(R.string.search_empty_query),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun SearchNoResults(
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

@Composable
private fun SearchResults(
    projects: List<SearchProjectItem>,
    tasks: List<SearchTaskItem>,
    onProjectClick: (SearchProjectItem) -> Unit,
    onTaskClick: (SearchTaskItem) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        // Projects section
        if (projects.isNotEmpty()) {
            item {
                SectionHeader(title = stringResource(R.string.search_section_projects))
            }

            items(
                items = projects,
                key = { "project_${it.project.id}" }
            ) { project ->
                SearchProjectRow(
                    item = project,
                    onClick = { onProjectClick(project) }
                )
            }

            item {
                HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
            }
        }

        // Tasks section
        if (tasks.isNotEmpty()) {
            item {
                SectionHeader(title = stringResource(R.string.search_section_tasks))
            }

            items(
                items = tasks,
                key = { "task_${it.task.id}" }
            ) { task ->
                SearchTaskRow(
                    item = task,
                    onClick = { onTaskClick(task) }
                )
            }
        }
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
        modifier = modifier.padding(horizontal = 16.dp, vertical = 8.dp)
    )
}

@Composable
private fun SearchProjectRow(
    item: SearchProjectItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    ListItem(
        headlineContent = {
            Text(
                text = item.project.title,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        },
        supportingContent = {
            Text(
                text = "${item.outstandingCount} remaining of ${item.taskCount} tasks",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        },
        leadingContent = {
            Icon(
                imageVector = Icons.Default.Folder,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
        },
        modifier = modifier.clickable(onClick = onClick),
        colors = ListItemDefaults.colors(containerColor = Color.Transparent)
    )
}

@Composable
private fun SearchTaskRow(
    item: SearchTaskItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    ListItem(
        headlineContent = {
            Text(
                text = item.task.title,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                textDecoration = if (item.isCompleted) TextDecoration.LineThrough else null,
                color = if (item.isCompleted) {
                    MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                } else {
                    MaterialTheme.colorScheme.onSurface
                }
            )
        },
        supportingContent = {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = item.projectName,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (item.task.priority != Priority.P4) {
                    PriorityBadge(priority = item.task.priority)
                }
            }
        },
        leadingContent = {
            Icon(
                imageVector = if (item.isCompleted) {
                    Icons.Default.CheckCircle
                } else {
                    Icons.Default.Circle
                },
                contentDescription = null,
                tint = if (item.isCompleted) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                },
                modifier = Modifier.size(24.dp)
            )
        },
        modifier = modifier.clickable(onClick = onClick),
        colors = ListItemDefaults.colors(containerColor = Color.Transparent)
    )
}

@Preview(showBackground = true)
@Composable
private fun SearchEmptyStatePreview() {
    LivePlanTheme {
        SearchEmptyState()
    }
}

@Preview(showBackground = true)
@Composable
private fun SearchResultsPreview() {
    LivePlanTheme {
        val projects = listOf(
            SearchProjectItem(
                project = Project(title = "Work Project", startDate = System.currentTimeMillis()),
                taskCount = 10,
                outstandingCount = 5
            )
        )
        val tasks = listOf(
            SearchTaskItem(
                task = Task(projectId = "1", title = "Complete UI design", priority = Priority.P1),
                projectName = "Work Project",
                isCompleted = false,
                tags = emptyList()
            ),
            SearchTaskItem(
                task = Task(projectId = "1", title = "Review code", priority = Priority.P2),
                projectName = "Work Project",
                isCompleted = true,
                tags = emptyList()
            )
        )

        SearchResults(
            projects = projects,
            tasks = tasks,
            onProjectClick = {},
            onTaskClick = {}
        )
    }
}
