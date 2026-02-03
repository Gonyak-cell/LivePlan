package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.Project
import com.liveplan.core.model.ProjectStatus
import com.liveplan.core.repository.ProjectRepository
import javax.inject.Inject

/**
 * Add project use case
 * Aligned with iOS AppCore AddProjectUseCase
 *
 * Creates a new project with required startDate
 */
class AddProjectUseCase @Inject constructor(
    private val projectRepository: ProjectRepository
) {
    /**
     * Add a new project
     *
     * @param title Project title (required)
     * @param startDate Start date in millis (required)
     * @param dueDate Due date in millis (optional, must be >= startDate)
     * @param note Project note (optional)
     * @return Result with created Project on success
     */
    suspend operator fun invoke(
        title: String,
        startDate: Long,
        dueDate: Long? = null,
        note: String? = null
    ): Result<Project> {
        // Validate title
        val trimmedTitle = title.trim()
        if (trimmedTitle.isBlank()) {
            return Result.failure(AppError.EmptyTitleError)
        }

        // Validate dueDate >= startDate
        if (dueDate != null && dueDate < startDate) {
            return Result.failure(
                AppError.ValidationError("dueDate must be >= startDate")
            )
        }

        return try {
            val project = Project(
                title = trimmedTitle,
                startDate = startDate,
                dueDate = dueDate,
                note = note,
                status = ProjectStatus.ACTIVE
            )

            projectRepository.addProject(project)
            Result.success(project)
        } catch (e: Exception) {
            Result.failure(AppError.StorageError(e))
        }
    }
}
