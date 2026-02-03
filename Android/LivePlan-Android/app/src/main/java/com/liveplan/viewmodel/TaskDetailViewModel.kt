package com.liveplan.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.Section
import com.liveplan.core.model.Tag
import com.liveplan.core.model.Task
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.SectionRepository
import com.liveplan.core.repository.TagRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.core.usecase.CompleteTaskUseCase
import com.liveplan.core.usecase.DeleteTaskUseCase
import com.liveplan.core.usecase.StartTaskUseCase
import com.liveplan.core.usecase.UncompleteTaskUseCase
import com.liveplan.core.util.DateKeyUtil
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
 * ViewModel for TaskDetailScreen
 */
@HiltViewModel
class TaskDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val taskRepository: TaskRepository,
    private val sectionRepository: SectionRepository,
    private val tagRepository: TagRepository,
    private val completionLogRepository: CompletionLogRepository,
    private val completeTaskUseCase: CompleteTaskUseCase,
    private val uncompleteTaskUseCase: UncompleteTaskUseCase,
    private val startTaskUseCase: StartTaskUseCase,
    private val deleteTaskUseCase: DeleteTaskUseCase
) : ViewModel() {

    private val taskId: String = checkNotNull(savedStateHandle[Screen.TaskDetail.ARG_TASK_ID])

    private val _uiState = MutableStateFlow<TaskDetailUiState>(TaskDetailUiState.Loading)
    val uiState: StateFlow<TaskDetailUiState> = _uiState.asStateFlow()

    private val _events = MutableSharedFlow<TaskDetailEvent>()
    val events: SharedFlow<TaskDetailEvent> = _events.asSharedFlow()

    init {
        loadTaskDetail()
    }

    private fun loadTaskDetail() {
        viewModelScope.launch {
            try {
                combine(
                    completionLogRepository.getLogsForTask(taskId),
                    tagRepository.getAllTags()
                ) { logs, allTags ->
                    val task = taskRepository.getTaskById(taskId)
                    if (task == null) {
                        TaskDetailUiState.NotFound
                    } else {
                        val dateKey = DateKeyUtil.today()
                        val isCompleted = isTaskCompleted(task, logs, dateKey)
                        val section = task.sectionId?.let { sectionId ->
                            sectionRepository.getSectionById(sectionId)
                        }
                        val tags = allTags.filter { it.id in task.tagIds }

                        TaskDetailUiState.Success(
                            task = task,
                            isCompleted = isCompleted,
                            section = section,
                            tags = tags
                        )
                    }
                }.collect { state ->
                    _uiState.value = state
                }
            } catch (e: Exception) {
                _uiState.value = TaskDetailUiState.Error(
                    message = e.message ?: "Failed to load task"
                )
            }
        }
    }

    private fun isTaskCompleted(task: Task, logs: List<CompletionLog>, dateKey: String): Boolean {
        return if (task.isOneOff) {
            logs.any { it.occurrenceKey == "once" }
        } else {
            logs.any { it.occurrenceKey == dateKey }
        }
    }

    fun toggleComplete() {
        val currentState = uiState.value as? TaskDetailUiState.Success ?: return

        viewModelScope.launch {
            val result = if (currentState.isCompleted) {
                uncompleteTaskUseCase(taskId)
            } else {
                completeTaskUseCase(taskId)
            }

            result.onFailure { error ->
                _events.emit(TaskDetailEvent.ShowError(error.message ?: "Failed to update task"))
            }
        }
    }

    fun startTask() {
        viewModelScope.launch {
            val result = startTaskUseCase(taskId)

            result.fold(
                onSuccess = {
                    _events.emit(TaskDetailEvent.ShowMessage("Task started"))
                },
                onFailure = { error ->
                    _events.emit(TaskDetailEvent.ShowError(error.message ?: "Failed to start task"))
                }
            )
        }
    }

    fun deleteTask() {
        viewModelScope.launch {
            val result = deleteTaskUseCase(taskId)

            result.fold(
                onSuccess = {
                    _events.emit(TaskDetailEvent.TaskDeleted)
                },
                onFailure = { error ->
                    _events.emit(TaskDetailEvent.ShowError(error.message ?: "Failed to delete task"))
                }
            )
        }
    }

    fun retry() {
        _uiState.value = TaskDetailUiState.Loading
        loadTaskDetail()
    }
}

/**
 * UI State for TaskDetailScreen
 */
sealed interface TaskDetailUiState {
    data object Loading : TaskDetailUiState
    data object NotFound : TaskDetailUiState

    data class Success(
        val task: Task,
        val isCompleted: Boolean,
        val section: Section?,
        val tags: List<Tag>
    ) : TaskDetailUiState

    data class Error(val message: String) : TaskDetailUiState
}

/**
 * One-time events for TaskDetailScreen
 */
sealed interface TaskDetailEvent {
    data object TaskDeleted : TaskDetailEvent
    data class ShowError(val message: String) : TaskDetailEvent
    data class ShowMessage(val message: String) : TaskDetailEvent
}
