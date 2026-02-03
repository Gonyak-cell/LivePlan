package com.liveplan.viewmodel

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Label
import androidx.compose.material.icons.filled.PriorityHigh
import androidx.compose.material.icons.filled.Today
import androidx.compose.material.icons.filled.Warning
import androidx.compose.ui.graphics.Color
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.DueRange
import com.liveplan.core.model.Priority
import com.liveplan.core.model.SavedView
import com.liveplan.core.model.Task
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.SavedViewRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.core.util.DateKeyUtil
import com.liveplan.ui.filter.BuiltInFilterItem
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel for FilterListScreen
 */
@HiltViewModel
class FilterListViewModel @Inject constructor(
    private val savedViewRepository: SavedViewRepository,
    private val taskRepository: TaskRepository,
    private val completionLogRepository: CompletionLogRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<FilterListUiState>(FilterListUiState.Loading)
    val uiState: StateFlow<FilterListUiState> = _uiState.asStateFlow()

    private val _events = MutableSharedFlow<FilterListEvent>()
    val events: SharedFlow<FilterListEvent> = _events.asSharedFlow()

    init {
        loadFilters()
    }

    private fun loadFilters() {
        viewModelScope.launch {
            try {
                combine(
                    savedViewRepository.getAllSavedViews(),
                    taskRepository.getAllTasks(),
                    completionLogRepository.getAllLogs()
                ) { savedViews, tasks, logs ->
                    val dateKey = DateKeyUtil.today()
                    val counts = calculateFilterCounts(tasks, logs, dateKey)

                    val builtInFilters = listOf(
                        BuiltInFilterItem(
                            id = "built-in-today",
                            name = "Today",
                            icon = Icons.Default.Today,
                            iconTint = Color(0xFF4CAF50),
                            count = counts.todayCount
                        ),
                        BuiltInFilterItem(
                            id = "built-in-upcoming",
                            name = "Upcoming",
                            icon = Icons.Default.CalendarMonth,
                            iconTint = Color(0xFF2196F3),
                            count = counts.upcomingCount
                        ),
                        BuiltInFilterItem(
                            id = "built-in-overdue",
                            name = "Overdue",
                            icon = Icons.Default.Warning,
                            iconTint = Color(0xFFF44336),
                            count = counts.overdueCount
                        ),
                        BuiltInFilterItem(
                            id = "built-in-p1",
                            name = "High Priority (P1)",
                            icon = Icons.Default.PriorityHigh,
                            iconTint = Color(0xFFFF9800),
                            count = counts.p1Count
                        ),
                        BuiltInFilterItem(
                            id = "built-in-by-tag",
                            name = "By Tag",
                            icon = Icons.Default.Label,
                            iconTint = Color(0xFF9C27B0),
                            count = 0
                        ),
                        BuiltInFilterItem(
                            id = "built-in-by-project",
                            name = "By Project",
                            icon = Icons.Default.Folder,
                            iconTint = Color(0xFF607D8B),
                            count = 0
                        )
                    )

                    // Filter out built-in from custom views
                    val customFilters = savedViews.filter { !it.id.startsWith("built-in") }

                    FilterListUiState.Success(
                        builtInFilters = builtInFilters,
                        customFilters = customFilters
                    )
                }.collect { state ->
                    _uiState.value = state
                }
            } catch (e: Exception) {
                _uiState.value = FilterListUiState.Error(e.message ?: "Failed to load filters")
            }
        }
    }

    private fun calculateFilterCounts(
        tasks: List<Task>,
        logs: List<CompletionLog>,
        dateKey: String
    ): FilterCounts {
        val now = System.currentTimeMillis()
        val todayStart = DateKeyUtil.startOfDay(now)
        val todayEnd = DateKeyUtil.endOfDay(now)
        val next7DaysEnd = todayEnd + 7 * 24 * 60 * 60 * 1000

        var todayCount = 0
        var upcomingCount = 0
        var overdueCount = 0
        var p1Count = 0

        tasks.forEach { task ->
            val isCompleted = isTaskCompleted(task, logs, dateKey)
            if (isCompleted) return@forEach

            val dueAt = task.dueAt
            if (dueAt != null) {
                when {
                    dueAt < now -> overdueCount++
                    dueAt in todayStart..todayEnd -> todayCount++
                    dueAt <= next7DaysEnd -> upcomingCount++
                }
            }

            if (task.priority == Priority.P1) {
                p1Count++
            }
        }

        return FilterCounts(
            todayCount = todayCount,
            upcomingCount = upcomingCount,
            overdueCount = overdueCount,
            p1Count = p1Count
        )
    }

    private fun isTaskCompleted(task: Task, logs: List<CompletionLog>, dateKey: String): Boolean {
        return if (task.isOneOff) {
            logs.any { it.taskId == task.id && it.occurrenceKey == "once" }
        } else {
            logs.any { it.taskId == task.id && it.occurrenceKey == dateKey }
        }
    }

    fun deleteFilter(filterId: String) {
        viewModelScope.launch {
            try {
                savedViewRepository.deleteSavedView(filterId)
                _events.emit(FilterListEvent.FilterDeleted)
            } catch (e: Exception) {
                _events.emit(FilterListEvent.ShowError(e.message ?: "Failed to delete filter"))
            }
        }
    }

    fun retry() {
        _uiState.value = FilterListUiState.Loading
        loadFilters()
    }
}

private data class FilterCounts(
    val todayCount: Int,
    val upcomingCount: Int,
    val overdueCount: Int,
    val p1Count: Int
)

/**
 * UI State for FilterListScreen
 */
sealed interface FilterListUiState {
    data object Loading : FilterListUiState

    data class Success(
        val builtInFilters: List<BuiltInFilterItem>,
        val customFilters: List<SavedView>
    ) : FilterListUiState

    data class Error(val message: String) : FilterListUiState
}

/**
 * One-time events for FilterListScreen
 */
sealed interface FilterListEvent {
    data object FilterDeleted : FilterListEvent
    data class ShowError(val message: String) : FilterListEvent
}
