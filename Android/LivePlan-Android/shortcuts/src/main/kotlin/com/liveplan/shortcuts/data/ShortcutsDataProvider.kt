package com.liveplan.shortcuts.data

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
import com.liveplan.core.usecase.AddTaskUseCase
import com.liveplan.core.usecase.CompleteTaskUseCase
import com.liveplan.core.util.DateKeyUtil
import com.liveplan.data.datastore.AppSettingsDataStore
import com.liveplan.shortcuts.R
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Provides data for shortcuts module (Tiles, Notifications, App Shortcuts)
 *
 * Responsible for:
 * - Computing lock screen summary for display
 * - Executing complete task action
 * - Quick add task action
 */
@Singleton
class ShortcutsDataProvider @Inject constructor(
    @ApplicationContext private val context: Context,
    private val projectRepository: ProjectRepository,
    private val taskRepository: TaskRepository,
    private val completionLogRepository: CompletionLogRepository,
    private val appSettingsDataStore: AppSettingsDataStore,
    private val outstandingComputer: OutstandingComputer,
    private val completeTaskUseCase: CompleteTaskUseCase,
    private val addTaskUseCase: AddTaskUseCase
) {
    /**
     * Get current lock screen summary
     *
     * @return LockScreenSummary or EMPTY on error
     */
    suspend fun getSummary(): LockScreenSummary {
        return try {
            val projects = projectRepository.getAllProjects().first()
            val tasks = taskRepository.getAllTasks().first()
            val completionLogs = completionLogRepository.getAllLogs().first()
            val settings = appSettingsDataStore.settings.first()

            computeSummary(projects, tasks, completionLogs, settings)
        } catch (e: Exception) {
            LockScreenSummary.EMPTY
        }
    }

    /**
     * Get the next task to complete (displayList[0])
     *
     * @return Next task or null if none available
     */
    suspend fun getNextTask(): Task? {
        return getSummary().displayList.firstOrNull()?.task
    }

    /**
     * Complete the next task in displayList
     *
     * @return Result with completed task title or error message
     */
    suspend fun completeNextTask(): ShortcutResult {
        return try {
            val summary = getSummary()
            val nextTask = summary.displayList.firstOrNull()?.task
                ?: return ShortcutResult.Error(
                    context.getString(R.string.error_no_task_to_complete)
                )

            val settings = appSettingsDataStore.settings.first()
            val dateKey = DateKeyUtil.today()

            val result = completeTaskUseCase(nextTask.id, dateKey)

            result.fold(
                onSuccess = {
                    val message = getCompletedMessage(nextTask.title, settings.privacyMode)
                    ShortcutResult.Success(message)
                },
                onFailure = { error ->
                    ShortcutResult.Error(error.message ?: "Failed to complete task")
                }
            )
        } catch (e: Exception) {
            ShortcutResult.Error(e.message ?: "An error occurred")
        }
    }

    /**
     * Quick add a task with title
     *
     * @param title Task title
     * @return Result with success message or error
     */
    suspend fun quickAddTask(title: String): ShortcutResult {
        return try {
            if (title.isBlank()) {
                return ShortcutResult.Error(
                    context.getString(R.string.error_empty_title)
                )
            }

            val settings = appSettingsDataStore.settings.first()
            val projectId = getDefaultProjectId(settings)
                ?: return ShortcutResult.Error(
                    context.getString(R.string.error_no_project)
                )

            val result = addTaskUseCase(
                projectId = projectId,
                title = title
            )

            result.fold(
                onSuccess = {
                    ShortcutResult.Success(
                        context.getString(R.string.task_added_success)
                    )
                },
                onFailure = { error ->
                    ShortcutResult.Error(error.message ?: "Failed to add task")
                }
            )
        } catch (e: Exception) {
            ShortcutResult.Error(e.message ?: "An error occurred")
        }
    }

    /**
     * Get current settings
     */
    suspend fun getSettings(): AppSettings {
        return try {
            appSettingsDataStore.settings.first()
        } catch (e: Exception) {
            AppSettings()
        }
    }

    /**
     * Get privacy-aware message for completed task
     */
    private fun getCompletedMessage(title: String, privacyMode: PrivacyMode): String {
        return when (privacyMode) {
            PrivacyMode.LEVEL_0 -> context.getString(
                R.string.task_completed_with_title,
                title.take(20)
            )
            PrivacyMode.LEVEL_1, PrivacyMode.LEVEL_2 -> context.getString(
                R.string.task_completed_simple
            )
        }
    }

    /**
     * Get default project ID for quick add
     * Priority: pinned project > first active project > inbox
     */
    private suspend fun getDefaultProjectId(settings: AppSettings): String? {
        // Use pinned project if available
        settings.pinnedProjectId?.let { return it }

        // Otherwise use first active project
        val projects = projectRepository.getAllProjects().first()
        return projects.firstOrNull { it.isActive }?.id
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

/**
 * Result of shortcut action
 */
sealed class ShortcutResult {
    data class Success(val message: String) : ShortcutResult()
    data class Error(val message: String) : ShortcutResult()
}
