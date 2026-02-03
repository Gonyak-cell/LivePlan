package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.Project
import com.liveplan.core.model.ProjectStatus
import com.liveplan.core.repository.ProjectRepository
import javax.inject.Inject

/**
 * Update project use case
 * Aligned with iOS AppCore UpdateProjectUseCase
 *
 * Updates existing project properties
 */
class UpdateProjectUseCase @Inject constructor(
    private val projectRepository: ProjectRepository
) {
    /**
     * Update a project with new values
     *
     * @param projectId Project ID to update
     * @param title New title (optional)
     * @param startDate New start date (optional)
     * @param dueDate New due date (optional, pass null to clear)
     * @param note New note (optional)
     * @param status New status (optional)
     * @return Result with updated Project on success
     */
    suspend operator fun invoke(
        projectId: String,
        title: String? = null,
        startDate: Long? = null,
        dueDate: Long? = null,
        clearDueDate: Boolean = false,
        note: String? = null,
        clearNote: Boolean = false,
        status: ProjectStatus? = null
    ): Result<Project> {
        return try {
            val existingProject = projectRepository.getProjectById(projectId)
                ?: return Result.failure(
                    AppError.NotFoundError("Project", projectId)
                )

            // Validate title if provided
            val newTitle = title?.trim()
            if (newTitle != null && newTitle.isBlank()) {
                return Result.failure(AppError.EmptyTitleError)
            }

            // Calculate new values
            val newStartDate = startDate ?: existingProject.startDate
            val newDueDate = when {
                clearDueDate -> null
                dueDate != null -> dueDate
                else -> existingProject.dueDate
            }

            // Validate dueDate >= startDate
            if (newDueDate != null && newDueDate < newStartDate) {
                return Result.failure(
                    AppError.ValidationError("dueDate must be >= startDate")
                )
            }

            val updatedProject = existingProject.copy(
                title = newTitle ?: existingProject.title,
                startDate = newStartDate,
                dueDate = newDueDate,
                note = when {
                    clearNote -> null
                    note != null -> note
                    else -> existingProject.note
                },
                status = status ?: existingProject.status,
                updatedAt = System.currentTimeMillis()
            )

            projectRepository.updateProject(updatedProject)
            Result.success(updatedProject)
        } catch (e: Exception) {
            Result.failure(AppError.StorageError(e))
        }
    }
}
