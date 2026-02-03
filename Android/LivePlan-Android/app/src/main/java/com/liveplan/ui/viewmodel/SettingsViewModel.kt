package com.liveplan.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liveplan.core.model.AppSettings
import com.liveplan.core.model.PrivacyMode
import com.liveplan.core.model.Project
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.data.datastore.AppSettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel for SettingsScreen
 */
@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsDataStore: AppSettingsDataStore,
    private val projectRepository: ProjectRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    private val _events = MutableSharedFlow<Event>()
    val events: SharedFlow<Event> = _events.asSharedFlow()

    init {
        loadSettings()
    }

    private fun loadSettings() {
        viewModelScope.launch {
            try {
                combine(
                    settingsDataStore.settings,
                    projectRepository.getAllProjects()
                ) { settings, projects ->
                    val pinnedProject = settings.pinnedProjectId?.let { pinnedId ->
                        projects.find { it.id == pinnedId }
                    }
                    SettingsUiState(
                        settings = settings,
                        projects = projects,
                        pinnedProject = pinnedProject,
                        isLoading = false
                    )
                }.collect { state ->
                    _uiState.value = state
                }
            } catch (e: Exception) {
                _events.emit(Event.Error(e.message ?: "Failed to load settings"))
            }
        }
    }

    fun setPrivacyMode(mode: PrivacyMode) {
        viewModelScope.launch {
            try {
                settingsDataStore.setPrivacyMode(mode)
                _events.emit(Event.SettingsUpdated)
            } catch (e: Exception) {
                _events.emit(Event.Error(e.message ?: "Failed to update privacy mode"))
            }
        }
    }

    fun setPinnedProject(projectId: String?) {
        viewModelScope.launch {
            try {
                settingsDataStore.setPinnedProjectId(projectId)
                _events.emit(Event.SettingsUpdated)
            } catch (e: Exception) {
                _events.emit(Event.Error(e.message ?: "Failed to update pinned project"))
            }
        }
    }

    fun setQuickAddParsing(enabled: Boolean) {
        viewModelScope.launch {
            try {
                settingsDataStore.setQuickAddParsing(enabled)
                _events.emit(Event.SettingsUpdated)
            } catch (e: Exception) {
                _events.emit(Event.Error(e.message ?: "Failed to update quick add setting"))
            }
        }
    }

    sealed class Event {
        data object SettingsUpdated : Event()
        data class Error(val message: String) : Event()
    }
}

/**
 * UI State for SettingsScreen
 */
data class SettingsUiState(
    val settings: AppSettings = AppSettings.DEFAULT,
    val projects: List<Project> = emptyList(),
    val pinnedProject: Project? = null,
    val isLoading: Boolean = true
)
