package com.liveplan.widget.data

import android.content.Context
import com.liveplan.core.model.AppSettings
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.PrivacyMode
import com.liveplan.core.model.Project
import com.liveplan.core.model.Task
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.core.selection.LockScreenSummary
import com.liveplan.core.selection.OutstandingComputer
import com.liveplan.core.util.DateKeyUtil
import com.liveplan.data.datastore.AppSettingsDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Provides widget data by computing LockScreenSummary
 *
 * This class is responsible for fetching all necessary data
 * and computing the lock screen summary for widget display.
 */
@Singleton
class WidgetDataProvider @Inject constructor(
    @ApplicationContext private val context: Context,
    private val projectRepository: ProjectRepository,
    private val taskRepository: TaskRepository,
    private val completionLogRepository: CompletionLogRepository,
    private val appSettingsDataStore: AppSettingsDataStore,
    private val outstandingComputer: OutstandingComputer
) {
    /**
     * Get widget state with computed lock screen summary
     *
     * This is a suspend function that:
     * 1. Fetches all projects, tasks, and completion logs
     * 2. Gets current app settings (privacy mode, pinned project, etc.)
     * 3. Computes the lock screen summary using OutstandingComputer
     *
     * @return WidgetState containing the computed summary or error
     */
    suspend fun getWidgetState(): WidgetState {
        return try {
            // Fetch all data in parallel
            val projects = projectRepository.getAllProjects().first()
            val tasks = taskRepository.getAllTasks().first()
            val completionLogs = completionLogRepository.getAllLogs().first()
            val settings = appSettingsDataStore.settings.first()

            // Compute lock screen summary
            val summary = computeSummary(
                projects = projects,
                tasks = tasks,
                completionLogs = completionLogs,
                settings = settings
            )

            WidgetState.Success(summary)
        } catch (e: Exception) {
            // Fail-safe: return empty state on error
            WidgetState.Error(e.message)
        }
    }

    /**
     * Get current privacy mode from settings
     */
    suspend fun getPrivacyMode(): PrivacyMode {
        return try {
            appSettingsDataStore.settings.first().privacyMode
        } catch (e: Exception) {
            PrivacyMode.DEFAULT
        }
    }

    private fun computeSummary(
        projects: List<Project>,
        tasks: List<Task>,
        completionLogs: List<CompletionLog>,
        settings: AppSettings
    ): LockScreenSummary {
        val dateKey = DateKeyUtil.today()

        return outstandingComputer.compute(
            dateKey = dateKey,
            pinnedProjectId = settings.pinnedProjectId,
            privacyMode = settings.privacyMode,
            selectionPolicy = settings.lockscreenSelectionMode,
            projects = projects,
            tasks = tasks,
            completionLogs = completionLogs,
            nowMillis = System.currentTimeMillis()
        )
    }
}
