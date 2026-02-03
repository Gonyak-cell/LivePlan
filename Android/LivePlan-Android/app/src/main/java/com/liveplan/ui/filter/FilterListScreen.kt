package com.liveplan.ui.filter

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Label
import androidx.compose.material.icons.filled.PriorityHigh
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Today
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.liveplan.R
import com.liveplan.core.model.FilterDefinition
import com.liveplan.core.model.SavedView
import com.liveplan.core.model.ViewScope
import com.liveplan.ui.common.EmptyState
import com.liveplan.ui.common.FullScreenLoading
import com.liveplan.ui.common.GenericErrorState
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.FilterListEvent
import com.liveplan.viewmodel.FilterListUiState
import com.liveplan.viewmodel.FilterListViewModel

/**
 * Filter list screen showing built-in and custom filters
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FilterListScreen(
    onNavigateBack: () -> Unit,
    onNavigateToFilter: (String) -> Unit,
    onNavigateToCreateFilter: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: FilterListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is FilterListEvent.ShowError -> {
                    snackbarHostState.showSnackbar(event.message)
                }
                is FilterListEvent.FilterDeleted -> {
                    snackbarHostState.showSnackbar("Filter deleted")
                }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.filters_title)) },
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
        floatingActionButton = {
            FloatingActionButton(onClick = onNavigateToCreateFilter) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = stringResource(R.string.action_create_filter)
                )
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
        modifier = modifier
    ) { paddingValues ->
        when (val state = uiState) {
            is FilterListUiState.Loading -> {
                FullScreenLoading()
            }
            is FilterListUiState.Error -> {
                GenericErrorState(onRetry = { viewModel.retry() })
            }
            is FilterListUiState.Success -> {
                FilterListContent(
                    builtInFilters = state.builtInFilters,
                    customFilters = state.customFilters,
                    onFilterClick = onNavigateToFilter,
                    onDeleteFilter = { viewModel.deleteFilter(it) },
                    onCreateFilter = onNavigateToCreateFilter,
                    modifier = Modifier.padding(paddingValues)
                )
            }
        }
    }
}

@Composable
private fun FilterListContent(
    builtInFilters: List<BuiltInFilterItem>,
    customFilters: List<SavedView>,
    onFilterClick: (String) -> Unit,
    onDeleteFilter: (String) -> Unit,
    onCreateFilter: () -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        // Built-in filters section
        item {
            Text(
                text = stringResource(R.string.filter_built_in),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )
        }

        items(builtInFilters) { filter ->
            BuiltInFilterRow(
                filter = filter,
                onClick = { onFilterClick(filter.id) }
            )
        }

        item {
            HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp))
        }

        // Custom filters section
        item {
            Text(
                text = stringResource(R.string.filter_custom),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )
        }

        if (customFilters.isEmpty()) {
            item {
                EmptyCustomFiltersState(
                    onCreateFilter = onCreateFilter,
                    modifier = Modifier.padding(16.dp)
                )
            }
        } else {
            items(
                items = customFilters,
                key = { it.id }
            ) { filter ->
                CustomFilterRow(
                    filter = filter,
                    onClick = { onFilterClick(filter.id) },
                    onDelete = { onDeleteFilter(filter.id) }
                )
            }
        }
    }
}

@Composable
private fun BuiltInFilterRow(
    filter: BuiltInFilterItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    ListItem(
        headlineContent = { Text(filter.name) },
        leadingContent = {
            Icon(
                imageVector = filter.icon,
                contentDescription = null,
                tint = filter.iconTint
            )
        },
        trailingContent = if (filter.count > 0) {
            {
                Text(
                    text = filter.count.toString(),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else null,
        modifier = modifier.clickable(onClick = onClick),
        colors = ListItemDefaults.colors(
            containerColor = Color.Transparent
        )
    )
}

@Composable
private fun CustomFilterRow(
    filter: SavedView,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    ListItem(
        headlineContent = { Text(filter.name) },
        leadingContent = {
            Icon(
                imageVector = Icons.Default.FilterList,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
        },
        trailingContent = {
            IconButton(onClick = onDelete) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = stringResource(R.string.action_delete),
                    tint = MaterialTheme.colorScheme.error
                )
            }
        },
        modifier = modifier.clickable(onClick = onClick),
        colors = ListItemDefaults.colors(
            containerColor = Color.Transparent
        )
    )
}

@Composable
private fun EmptyCustomFiltersState(
    onCreateFilter: () -> Unit,
    modifier: Modifier = Modifier
) {
    EmptyState(
        icon = Icons.Default.FilterList,
        title = stringResource(R.string.filter_no_custom),
        description = stringResource(R.string.filter_no_custom_description),
        actionLabel = stringResource(R.string.action_create_filter),
        onAction = onCreateFilter,
        modifier = modifier
    )
}

/**
 * Built-in filter item for display
 */
data class BuiltInFilterItem(
    val id: String,
    val name: String,
    val icon: ImageVector,
    val iconTint: Color,
    val count: Int = 0
)

@Preview(showBackground = true)
@Composable
private fun FilterListContentPreview() {
    LivePlanTheme {
        val builtInFilters = listOf(
            BuiltInFilterItem(
                id = "today",
                name = "Today",
                icon = Icons.Default.Today,
                iconTint = Color(0xFF4CAF50),
                count = 5
            ),
            BuiltInFilterItem(
                id = "upcoming",
                name = "Upcoming",
                icon = Icons.Default.CalendarMonth,
                iconTint = Color(0xFF2196F3),
                count = 12
            ),
            BuiltInFilterItem(
                id = "overdue",
                name = "Overdue",
                icon = Icons.Default.Warning,
                iconTint = Color(0xFFF44336),
                count = 2
            ),
            BuiltInFilterItem(
                id = "p1",
                name = "High Priority (P1)",
                icon = Icons.Default.PriorityHigh,
                iconTint = Color(0xFFFF9800),
                count = 3
            )
        )

        val customFilters = listOf(
            SavedView(
                id = "custom1",
                name = "Work Tasks",
                scope = ViewScope.Global,
                definition = FilterDefinition.DEFAULT
            )
        )

        FilterListContent(
            builtInFilters = builtInFilters,
            customFilters = customFilters,
            onFilterClick = {},
            onDeleteFilter = {},
            onCreateFilter = {}
        )
    }
}
