package com.liveplan.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liveplan.core.model.Priority
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.RecurrenceKind
import com.liveplan.core.model.RecurrenceRule
import com.liveplan.core.model.Section
import com.liveplan.core.model.Tag
import com.liveplan.core.repository.SectionRepository
import com.liveplan.core.repository.TagRepository
import com.liveplan.core.usecase.AddTaskUseCase
import com.liveplan.navigation.Screen
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
 * ViewModel for TaskCreateScreen
 */
@HiltViewModel
class TaskCreateViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val sectionRepository: SectionRepository,
    private val tagRepository: TagRepository,
    private val addTaskUseCase: AddTaskUseCase
) : ViewModel() {

    private val projectId: String = checkNotNull(savedStateHandle[Screen.TaskCreate.ARG_PROJECT_ID])

    private val _uiState = MutableStateFlow<TaskCreateUiState>(TaskCreateUiState.Loading)
    val uiState: StateFlow<TaskCreateUiState> = _uiState.asStateFlow()

    private val _events = MutableSharedFlow<TaskCreateEvent>()
    val events: SharedFlow<TaskCreateEvent> = _events.asSharedFlow()

    init {
        loadFormData()
    }

    private fun loadFormData() {
        viewModelScope.launch {
            try {
                combine(
                    sectionRepository.getSectionsByProject(projectId),
                    tagRepository.getAllTags()
                ) { sections, tags ->
                    TaskCreateUiState.Ready(
                        sections = sections,
                        tags = tags
                    )
                }.collect { state ->
                    _uiState.value = state
                }
            } catch (e: Exception) {
                _uiState.value = TaskCreateUiState.Ready(
                    sections = emptyList(),
                    tags = emptyList()
                )
            }
        }
    }

    fun createTask(
        title: String,
        priority: Priority,
        dueAt: Long?,
        recurrenceKind: RecurrenceKind?,
        sectionId: String?,
        tagIds: List<String>,
        note: String?
    ) {
        viewModelScope.launch {
            _uiState.value = TaskCreateUiState.Saving

            val recurrenceRule = recurrenceKind?.let { kind ->
                when (kind) {
                    RecurrenceKind.DAILY -> RecurrenceRule.daily()
                    RecurrenceKind.WEEKLY -> {
                        // Default to current day of week if no specific days
                        val currentDayOfWeek = java.time.DayOfWeek.from(
                            java.time.LocalDate.now()
                        )
                        RecurrenceRule.weekly(setOf(currentDayOfWeek))
                    }
                    RecurrenceKind.MONTHLY -> RecurrenceRule(
                        kind = RecurrenceKind.MONTHLY,
                        anchorDateMillis = System.currentTimeMillis()
                    )
                }
            }

            val recurrenceBehavior = if (recurrenceRule != null) {
                // Default to habit reset for daily, rollover for others
                if (recurrenceKind == RecurrenceKind.DAILY) {
                    RecurrenceBehavior.HABIT_RESET
                } else {
                    RecurrenceBehavior.ROLLOVER
                }
            } else {
                RecurrenceBehavior.DEFAULT
            }

            val result = addTaskUseCase(
                projectId = projectId,
                title = title,
                priority = priority,
                dueAt = dueAt,
                recurrenceRule = recurrenceRule,
                recurrenceBehavior = recurrenceBehavior,
                sectionId = sectionId,
                tagIds = tagIds,
                note = note
            )

            result.fold(
                onSuccess = { task ->
                    _events.emit(TaskCreateEvent.TaskCreated(task.id))
                },
                onFailure = { error ->
                    _uiState.value = TaskCreateUiState.Ready(
                        sections = (uiState.value as? TaskCreateUiState.Ready)?.sections ?: emptyList(),
                        tags = (uiState.value as? TaskCreateUiState.Ready)?.tags ?: emptyList()
                    )
                    _events.emit(TaskCreateEvent.ShowError(error.message ?: "Failed to create task"))
                }
            )
        }
    }
}

/**
 * UI State for TaskCreateScreen
 */
sealed interface TaskCreateUiState {
    data object Loading : TaskCreateUiState
    data object Saving : TaskCreateUiState

    data class Ready(
        val sections: List<Section>,
        val tags: List<Tag>
    ) : TaskCreateUiState
}

/**
 * One-time events for TaskCreateScreen
 */
sealed interface TaskCreateEvent {
    data class TaskCreated(val taskId: String) : TaskCreateEvent
    data class ShowError(val message: String) : TaskCreateEvent
}
