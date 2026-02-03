package com.liveplan.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liveplan.core.model.Project
import com.liveplan.core.model.Task
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.core.usecase.AddProjectUseCase
import com.liveplan.core.util.DateKeyUtil
import com.liveplan.data.datastore.AppSettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel for ProjectListScreen
 */
@HiltViewModel
class ProjectListViewModel @Inject constructor(
    private val projectRepository: ProjectRepository,
    private val taskRepository: TaskRepository,
    private val completionLogRepository: CompletionLogRepository,
    private val appSettingsDataStore: AppSettingsDataStore,
    private val addProjectUseCase: AddProjectUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow<ProjectListUiState>(ProjectListUiState.Loading)
    val uiState: StateFlow<ProjectListUiState> = _uiState.asStateFlow()

    private val _events = MutableSharedFlow<ProjectListEvent>()
    val events: SharedFlow<ProjectListEvent> = _events.asSharedFlow()

    private val _showCreateDialog = MutableStateFlow(false)
    val showCreateDialog: StateFlow<Boolean> = _showCreateDialog.asStateFlow()

    init {
        loadProjects()
    }

    private fun loadProjects() {
        viewModelScope.launch {
            try {
                combine(
                    projectRepository.getActiveProjects(),
                    taskRepository.getAllTasks(),
                    completionLogRepository.getAllLogs(),
                    appSettingsDataStore.settings.map { it.pinnedProjectId }
                ) { projects, tasks, logs, pinnedProjectId ->
                    val dateKey = DateKeyUtil.today()
                    val projectItems = projects.map { project ->
                        val projectTasks = tasks.filter { it.projectId == project.id }
                        val completedCount = countCompletedTasks(projectTasks, logs, dateKey)
                        ProjectListItem(
                            project = project,
                            taskCount = projectTasks.size,
                            completedCount = completedCount,
                            isPinned = project.id == pinnedProjectId
                        )
                    }.sortedWith(
                        compareByDescending<ProjectListItem> { it.isPinned }
                            .thenByDescending { it.project.updatedAt }
                    )

                    ProjectListUiState.Success(
                        projects = projectItems,
                        pinnedProjectId = pinnedProjectId
                    )
                }.collect { state ->
                    _uiState.value = state
                }
            } catch (e: Exception) {
                _uiState.value = ProjectListUiState.Error(
                    message = e.message ?: "Failed to load projects"
                )
            }
        }
    }

    private fun countCompletedTasks(
        tasks: List<Task>,
        logs: List<com.liveplan.core.model.CompletionLog>,
        dateKey: String
    ): Int {
        return tasks.count { task ->
            if (task.isOneOff) {
                logs.any { it.taskId == task.id && it.occurrenceKey == "once" }
            } else {
                logs.any { it.taskId == task.id && it.occurrenceKey == dateKey }
            }
        }
    }

    fun showCreateProjectDialog() {
        _showCreateDialog.value = true
    }

    fun dismissCreateProjectDialog() {
        _showCreateDialog.value = false
    }

    fun createProject(
        title: String,
        startDate: Long,
        dueDate: Long? = null,
        note: String? = null
    ) {
        viewModelScope.launch {
            val result = addProjectUseCase(
                title = title,
                startDate = startDate,
                dueDate = dueDate,
                note = note
            )

            result.fold(
                onSuccess = { project ->
                    _showCreateDialog.value = false
                    _events.emit(ProjectListEvent.ProjectCreated(project.id))
                },
                onFailure = { error ->
                    _events.emit(ProjectListEvent.ShowError(error.message ?: "Failed to create project"))
                }
            )
        }
    }

    fun setPinnedProject(projectId: String?) {
        viewModelScope.launch {
            appSettingsDataStore.setPinnedProjectId(projectId)
        }
    }

    fun retry() {
        _uiState.value = ProjectListUiState.Loading
        loadProjects()
    }
}

/**
 * UI State for ProjectListScreen
 */
sealed interface ProjectListUiState {
    data object Loading : ProjectListUiState

    data class Success(
        val projects: List<ProjectListItem>,
        val pinnedProjectId: String?
    ) : ProjectListUiState

    data class Error(val message: String) : ProjectListUiState
}

/**
 * Project list item with computed properties
 */
data class ProjectListItem(
    val project: Project,
    val taskCount: Int,
    val completedCount: Int,
    val isPinned: Boolean
)

/**
 * One-time events for ProjectListScreen
 */
sealed interface ProjectListEvent {
    data class ProjectCreated(val projectId: String) : ProjectListEvent
    data class ShowError(val message: String) : ProjectListEvent
}
