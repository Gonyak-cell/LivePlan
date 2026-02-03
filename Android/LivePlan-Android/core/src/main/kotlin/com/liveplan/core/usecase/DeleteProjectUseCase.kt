package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.Project
import com.liveplan.core.model.ProjectStatus
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.core.repository.TaskRepository
import kotlinx.coroutines.flow.first
import javax.inject.Inject

/**
 * Delete project use case
 * Aligned with iOS AppCore DeleteProjectUseCase
 *
 * Supports two modes:
 * - Archive: Sets status to ARCHIVED (soft delete, tasks preserved)
 * - Delete: Permanently removes project and all associated tasks/logs
 */
class DeleteProjectUseCase @Inject constructor(
    private val projectRepository: ProjectRepository,
    private val taskRepository: TaskRepository,
    private val completionLogRepository: CompletionLogRepository
) {
    /**
     * Delete or archive a project
     *
     * @param projectId Project ID to delete/archive
     * @param permanent If true, permanently delete; if false, archive (default: false)
     * @return Result with Unit on success
     */
    suspend operator fun invoke(
        projectId: String,
        permanent: Boolean = false
    ): Result<Unit> {
        return try {
            val project = projectRepository.getProjectById(projectId)
                ?: return Result.failure(
                    AppError.NotFoundError("Project", projectId)
                )

            if (permanent) {
                // Permanent delete: remove all associated data
                deleteProjectPermanently(projectId)
            } else {
                // Archive: soft delete by changing status
                archiveProject(project)
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(AppError.StorageError(e))
        }
    }

    private suspend fun archiveProject(project: Project) {
        val archivedProject = project.copy(
            status = ProjectStatus.ARCHIVED,
            updatedAt = System.currentTimeMillis()
        )
        projectRepository.updateProject(archivedProject)
    }

    private suspend fun deleteProjectPermanently(projectId: String) {
        // Get all tasks for this project
        val tasks = taskRepository.getTasksByProject(projectId).first()

        // Delete completion logs for each task
        for (task in tasks) {
            completionLogRepository.deleteLogsForTask(task.id)
        }

        // Delete all tasks
        for (task in tasks) {
            taskRepository.deleteTask(task.id)
        }

        // Delete the project
        projectRepository.deleteProject(projectId)
    }
}
