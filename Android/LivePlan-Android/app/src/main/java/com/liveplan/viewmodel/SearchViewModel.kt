package com.liveplan.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.Project
import com.liveplan.core.model.Task
import com.liveplan.core.model.Tag
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.core.repository.TagRepository
import com.liveplan.core.util.DateKeyUtil
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel for SearchScreen
 * Provides local string search across projects, tasks, notes, and tags
 */
@HiltViewModel
class SearchViewModel @Inject constructor(
    private val projectRepository: ProjectRepository,
    private val taskRepository: TaskRepository,
    private val tagRepository: TagRepository,
    private val completionLogRepository: CompletionLogRepository
) : ViewModel() {

    private val _query = MutableStateFlow("")
    val query: StateFlow<String> = _query.asStateFlow()

    private val _uiState = MutableStateFlow<SearchUiState>(SearchUiState.Empty)
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    init {
        observeSearchQuery()
    }

    @OptIn(FlowPreview::class)
    private fun observeSearchQuery() {
        viewModelScope.launch {
            _query
                .debounce(300) // Wait 300ms after user stops typing
                .distinctUntilChanged()
                .collect { query ->
                    if (query.isBlank()) {
                        _uiState.value = SearchUiState.Empty
                    } else {
                        performSearch(query)
                    }
                }
        }
    }

    private suspend fun performSearch(query: String) {
        _uiState.value = SearchUiState.Loading

        try {
            combine(
                projectRepository.getAllProjects(),
                taskRepository.getAllTasks(),
                tagRepository.getAllTags(),
                completionLogRepository.getAllLogs()
            ) { projects, tasks, tags, logs ->
                val dateKey = DateKeyUtil.today()
                val normalizedQuery = query.lowercase().trim()

                // Search projects
                val matchingProjects = projects.filter { project ->
                    project.title.lowercase().contains(normalizedQuery) ||
                    project.note?.lowercase()?.contains(normalizedQuery) == true
                }.map { project ->
                    val taskCount = tasks.count { it.projectId == project.id }
                    val outstandingCount = tasks.count { task ->
                        task.projectId == project.id && !isTaskCompleted(task, logs, dateKey)
                    }
                    SearchProjectItem(
                        project = project,
                        taskCount = taskCount,
                        outstandingCount = outstandingCount
                    )
                }

                // Search tasks
                val matchingTasks = tasks.filter { task ->
                    task.title.lowercase().contains(normalizedQuery) ||
                    task.note?.lowercase()?.contains(normalizedQuery) == true ||
                    // Search by tag name
                    task.tagIds.any { tagId ->
                        tags.find { it.id == tagId }?.name?.lowercase()?.contains(normalizedQuery) == true
                    }
                }.map { task ->
                    val project = projects.find { it.id == task.projectId }
                    val isCompleted = isTaskCompleted(task, logs, dateKey)
                    val taskTags = task.tagIds.mapNotNull { tagId -> tags.find { it.id == tagId } }
                    SearchTaskItem(
                        task = task,
                        projectName = project?.title ?: "Unknown",
                        isCompleted = isCompleted,
                        tags = taskTags
                    )
                }

                if (matchingProjects.isEmpty() && matchingTasks.isEmpty()) {
                    SearchUiState.NoResults(query)
                } else {
                    SearchUiState.Success(
                        query = query,
                        projects = matchingProjects,
                        tasks = matchingTasks
                    )
                }
            }.collect { state ->
                _uiState.value = state
            }
        } catch (e: Exception) {
            _uiState.value = SearchUiState.Error(e.message ?: "Search failed")
        }
    }

    private fun isTaskCompleted(task: Task, logs: List<CompletionLog>, dateKey: String): Boolean {
        return if (task.isOneOff) {
            logs.any { it.taskId == task.id && it.occurrenceKey == "once" }
        } else {
            logs.any { it.taskId == task.id && it.occurrenceKey == dateKey }
        }
    }

    fun setQuery(query: String) {
        _query.value = query
    }

    fun clearQuery() {
        _query.value = ""
        _uiState.value = SearchUiState.Empty
    }
}

/**
 * UI State for SearchScreen
 */
sealed interface SearchUiState {
    data object Empty : SearchUiState
    data object Loading : SearchUiState

    data class Success(
        val query: String,
        val projects: List<SearchProjectItem>,
        val tasks: List<SearchTaskItem>
    ) : SearchUiState

    data class NoResults(val query: String) : SearchUiState
    data class Error(val message: String) : SearchUiState
}

/**
 * Search result item for projects
 */
data class SearchProjectItem(
    val project: Project,
    val taskCount: Int,
    val outstandingCount: Int
)

/**
 * Search result item for tasks
 */
data class SearchTaskItem(
    val task: Task,
    val projectName: String,
    val isCompleted: Boolean,
    val tags: List<Tag>
)
