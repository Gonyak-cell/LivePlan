package com.liveplan.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.Project
import com.liveplan.core.model.Section
import com.liveplan.core.model.Task
import com.liveplan.core.model.ViewType
import com.liveplan.core.model.WorkflowState
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.core.repository.SectionRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.core.usecase.CompleteTaskUseCase
import com.liveplan.core.usecase.DeleteProjectUseCase
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
 * ViewModel for ProjectDetailScreen
 */
@HiltViewModel
class ProjectDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val projectRepository: ProjectRepository,
    private val taskRepository: TaskRepository,
    private val sectionRepository: SectionRepository,
    private val completionLogRepository: CompletionLogRepository,
    private val completeTaskUseCase: CompleteTaskUseCase,
    private val uncompleteTaskUseCase: UncompleteTaskUseCase,
    private val startTaskUseCase: StartTaskUseCase,
    private val deleteProjectUseCase: DeleteProjectUseCase
) : ViewModel() {

    private val projectId: String = checkNotNull(savedStateHandle[Screen.ProjectDetail.ARG_PROJECT_ID])

    private val _uiState = MutableStateFlow<ProjectDetailUiState>(ProjectDetailUiState.Loading)
    val uiState: StateFlow<ProjectDetailUiState> = _uiState.asStateFlow()

    private val _viewType = MutableStateFlow(ViewType.LIST)
    val viewType: StateFlow<ViewType> = _viewType.asStateFlow()

    private val _events = MutableSharedFlow<ProjectDetailEvent>()
    val events: SharedFlow<ProjectDetailEvent> = _events.asSharedFlow()

    init {
        loadProjectDetail()
    }

    private fun loadProjectDetail() {
        viewModelScope.launch {
            try {
                combine(
                    taskRepository.getTasksByProject(projectId),
                    sectionRepository.getSectionsByProject(projectId),
                    completionLogRepository.getAllLogs()
                ) { tasks, sections, allLogs ->
                    // Filter logs for tasks in this project
                    val taskIds = tasks.map { it.id }.toSet()
                    val logs = allLogs.filter { it.taskId in taskIds }
                    val project = projectRepository.getProjectById(projectId)

                    if (project == null) {
                        ProjectDetailUiState.NotFound
                    } else {
                        val dateKey = DateKeyUtil.today()
                        val taskItems = tasks.map { task ->
                            val isCompleted = isTaskCompleted(task, logs, dateKey)
                            TaskItem(
                                task = task,
                                isCompleted = isCompleted,
                                section = sections.find { it.id == task.sectionId }
                            )
                        }.sortedWith(
                            compareBy<TaskItem> { it.isCompleted }
                                .thenBy { it.task.priority.value }
                                .thenBy { it.task.dueAt ?: Long.MAX_VALUE }
                                .thenBy { it.task.createdAt }
                        )

                        ProjectDetailUiState.Success(
                            project = project,
                            tasks = taskItems,
                            sections = sections,
                            outstandingCount = taskItems.count { !it.isCompleted },
                            completedCount = taskItems.count { it.isCompleted }
                        )
                    }
                }.collect { state ->
                    _uiState.value = state
                }
            } catch (e: Exception) {
                _uiState.value = ProjectDetailUiState.Error(
                    message = e.message ?: "Failed to load project"
                )
            }
        }
    }

    private fun isTaskCompleted(task: Task, logs: List<CompletionLog>, dateKey: String): Boolean {
        return if (task.isOneOff) {
            logs.any { it.taskId == task.id && it.occurrenceKey == "once" }
        } else {
            logs.any { it.taskId == task.id && it.occurrenceKey == dateKey }
        }
    }

    fun toggleTaskComplete(taskId: String, isCurrentlyCompleted: Boolean) {
        viewModelScope.launch {
            val result = if (isCurrentlyCompleted) {
                uncompleteTaskUseCase(taskId)
            } else {
                completeTaskUseCase(taskId)
            }

            result.onFailure { error ->
                _events.emit(ProjectDetailEvent.ShowError(error.message ?: "Failed to update task"))
            }
        }
    }

    fun startTask(taskId: String) {
        viewModelScope.launch {
            val result = startTaskUseCase(taskId)

            result.onFailure { error ->
                _events.emit(ProjectDetailEvent.ShowError(error.message ?: "Failed to start task"))
            }
        }
    }

    fun setViewType(type: ViewType) {
        _viewType.value = type
    }

    fun deleteProject() {
        viewModelScope.launch {
            val result = deleteProjectUseCase(projectId)

            result.fold(
                onSuccess = {
                    _events.emit(ProjectDetailEvent.ProjectDeleted)
                },
                onFailure = { error ->
                    _events.emit(ProjectDetailEvent.ShowError(error.message ?: "Failed to delete project"))
                }
            )
        }
    }

    fun retry() {
        _uiState.value = ProjectDetailUiState.Loading
        loadProjectDetail()
    }
}

/**
 * UI State for ProjectDetailScreen
 */
sealed interface ProjectDetailUiState {
    data object Loading : ProjectDetailUiState
    data object NotFound : ProjectDetailUiState

    data class Success(
        val project: Project,
        val tasks: List<TaskItem>,
        val sections: List<Section>,
        val outstandingCount: Int,
        val completedCount: Int
    ) : ProjectDetailUiState

    data class Error(val message: String) : ProjectDetailUiState
}

/**
 * Task item with completion state
 */
data class TaskItem(
    val task: Task,
    val isCompleted: Boolean,
    val section: Section?
)

/**
 * One-time events for ProjectDetailScreen
 */
sealed interface ProjectDetailEvent {
    data object ProjectDeleted : ProjectDetailEvent
    data class ShowError(val message: String) : ProjectDetailEvent
}
