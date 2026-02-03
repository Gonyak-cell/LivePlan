package com.liveplan.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liveplan.core.model.DueRange
import com.liveplan.core.model.FilterDefinition
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Project
import com.liveplan.core.model.SavedView
import com.liveplan.core.model.Tag
import com.liveplan.core.model.ViewScope
import com.liveplan.core.model.ViewType
import com.liveplan.core.model.WorkflowState
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.core.repository.SavedViewRepository
import com.liveplan.core.repository.TagRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

/**
 * ViewModel for FilterBuilderScreen
 */
@HiltViewModel
class FilterBuilderViewModel @Inject constructor(
    private val savedViewRepository: SavedViewRepository,
    private val projectRepository: ProjectRepository,
    private val tagRepository: TagRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<FilterBuilderUiState>(FilterBuilderUiState.Loading)
    val uiState: StateFlow<FilterBuilderUiState> = _uiState.asStateFlow()

    private val _events = MutableSharedFlow<FilterBuilderEvent>()
    val events: SharedFlow<FilterBuilderEvent> = _events.asSharedFlow()

    private var editingFilterId: String? = null

    init {
        loadInitialData()
    }

    private fun loadInitialData() {
        viewModelScope.launch {
            try {
                val projects = projectRepository.getAllProjects().first()
                val tags = tagRepository.getAllTags().first()

                _uiState.value = FilterBuilderUiState.Success(
                    name = "",
                    availableProjects = projects,
                    selectedProjects = emptySet(),
                    availableTags = tags,
                    selectedTags = emptySet(),
                    selectedPriorities = Priority.entries.toSet(),
                    selectedStates = setOf(WorkflowState.TODO, WorkflowState.DOING),
                    dueRange = DueRange.NONE,
                    includeRecurring = true,
                    excludeBlocked = true
                )
            } catch (e: Exception) {
                _events.emit(FilterBuilderEvent.ShowError(e.message ?: "Failed to load data"))
            }
        }
    }

    fun loadFilter(filterId: String) {
        viewModelScope.launch {
            try {
                val savedView = savedViewRepository.getSavedViewById(filterId)
                if (savedView == null) {
                    _events.emit(FilterBuilderEvent.ShowError("Filter not found"))
                    return@launch
                }

                editingFilterId = filterId
                val currentState = _uiState.value
                if (currentState is FilterBuilderUiState.Success) {
                    val def = savedView.definition
                    _uiState.value = currentState.copy(
                        name = savedView.name,
                        selectedProjects = def.includeProjects?.toSet() ?: emptySet(),
                        selectedTags = def.includeTags?.toSet() ?: emptySet(),
                        selectedPriorities = getPrioritiesFromDefinition(def),
                        selectedStates = def.stateIn,
                        dueRange = def.dueRange,
                        includeRecurring = def.includeRecurring,
                        excludeBlocked = def.excludeBlocked
                    )
                }
            } catch (e: Exception) {
                _events.emit(FilterBuilderEvent.ShowError(e.message ?: "Failed to load filter"))
            }
        }
    }

    private fun getPrioritiesFromDefinition(def: FilterDefinition): Set<Priority> {
        val atMost = def.priorityAtMost
        val atLeast = def.priorityAtLeast

        return when {
            atMost != null && atLeast != null -> {
                Priority.entries.filter { it.value in atMost.value..atLeast.value }.toSet()
            }
            atMost != null -> {
                Priority.entries.filter { it.value <= atMost.value }.toSet()
            }
            atLeast != null -> {
                Priority.entries.filter { it.value >= atLeast.value }.toSet()
            }
            else -> Priority.entries.toSet()
        }
    }

    fun setName(name: String) {
        val currentState = _uiState.value
        if (currentState is FilterBuilderUiState.Success) {
            _uiState.value = currentState.copy(name = name)
        }
    }

    fun toggleProject(projectId: String) {
        val currentState = _uiState.value
        if (currentState is FilterBuilderUiState.Success) {
            val newSelection = if (projectId in currentState.selectedProjects) {
                currentState.selectedProjects - projectId
            } else {
                currentState.selectedProjects + projectId
            }
            _uiState.value = currentState.copy(selectedProjects = newSelection)
        }
    }

    fun toggleTag(tagId: String) {
        val currentState = _uiState.value
        if (currentState is FilterBuilderUiState.Success) {
            val newSelection = if (tagId in currentState.selectedTags) {
                currentState.selectedTags - tagId
            } else {
                currentState.selectedTags + tagId
            }
            _uiState.value = currentState.copy(selectedTags = newSelection)
        }
    }

    fun togglePriority(priority: Priority) {
        val currentState = _uiState.value
        if (currentState is FilterBuilderUiState.Success) {
            val newSelection = if (priority in currentState.selectedPriorities) {
                currentState.selectedPriorities - priority
            } else {
                currentState.selectedPriorities + priority
            }
            _uiState.value = currentState.copy(selectedPriorities = newSelection)
        }
    }

    fun toggleState(state: WorkflowState) {
        val currentState = _uiState.value
        if (currentState is FilterBuilderUiState.Success) {
            val newSelection = if (state in currentState.selectedStates) {
                currentState.selectedStates - state
            } else {
                currentState.selectedStates + state
            }
            _uiState.value = currentState.copy(selectedStates = newSelection)
        }
    }

    fun setDueRange(dueRange: DueRange) {
        val currentState = _uiState.value
        if (currentState is FilterBuilderUiState.Success) {
            _uiState.value = currentState.copy(dueRange = dueRange)
        }
    }

    fun setIncludeRecurring(include: Boolean) {
        val currentState = _uiState.value
        if (currentState is FilterBuilderUiState.Success) {
            _uiState.value = currentState.copy(includeRecurring = include)
        }
    }

    fun setExcludeBlocked(exclude: Boolean) {
        val currentState = _uiState.value
        if (currentState is FilterBuilderUiState.Success) {
            _uiState.value = currentState.copy(excludeBlocked = exclude)
        }
    }

    fun saveFilter() {
        viewModelScope.launch {
            val currentState = _uiState.value
            if (currentState !is FilterBuilderUiState.Success) return@launch

            if (currentState.name.isBlank()) {
                _events.emit(FilterBuilderEvent.ShowError("Filter name is required"))
                return@launch
            }

            try {
                val definition = buildFilterDefinition(currentState)
                val savedView = SavedView(
                    id = editingFilterId ?: UUID.randomUUID().toString(),
                    name = currentState.name,
                    scope = ViewScope.Global,
                    viewType = ViewType.LIST,
                    definition = definition
                )

                if (editingFilterId != null) {
                    savedViewRepository.updateSavedView(savedView)
                } else {
                    savedViewRepository.addSavedView(savedView)
                }

                _events.emit(FilterBuilderEvent.FilterSaved)
            } catch (e: Exception) {
                _events.emit(FilterBuilderEvent.ShowError(e.message ?: "Failed to save filter"))
            }
        }
    }

    private fun buildFilterDefinition(state: FilterBuilderUiState.Success): FilterDefinition {
        val priorities = state.selectedPriorities.sortedBy { it.value }
        val priorityAtMost = priorities.firstOrNull()
        val priorityAtLeast = priorities.lastOrNull()

        return FilterDefinition(
            includeProjects = state.selectedProjects.takeIf { it.isNotEmpty() }?.toList(),
            includeTags = state.selectedTags.takeIf { it.isNotEmpty() }?.toList(),
            includeSections = null,
            priorityAtMost = priorityAtMost,
            priorityAtLeast = priorityAtLeast,
            stateIn = state.selectedStates,
            dueRange = state.dueRange,
            includeRecurring = state.includeRecurring,
            excludeBlocked = state.excludeBlocked
        )
    }
}

/**
 * UI State for FilterBuilderScreen
 */
sealed interface FilterBuilderUiState {
    data object Loading : FilterBuilderUiState

    data class Success(
        val name: String,
        val availableProjects: List<Project>,
        val selectedProjects: Set<String>,
        val availableTags: List<Tag>,
        val selectedTags: Set<String>,
        val selectedPriorities: Set<Priority>,
        val selectedStates: Set<WorkflowState>,
        val dueRange: DueRange,
        val includeRecurring: Boolean,
        val excludeBlocked: Boolean
    ) : FilterBuilderUiState
}

/**
 * One-time events for FilterBuilderScreen
 */
sealed interface FilterBuilderEvent {
    data object FilterSaved : FilterBuilderEvent
    data class ShowError(val message: String) : FilterBuilderEvent
}
