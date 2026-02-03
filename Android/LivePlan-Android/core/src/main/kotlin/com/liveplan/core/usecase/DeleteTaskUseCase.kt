package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.TaskRepository
import javax.inject.Inject

/**
 * Delete task use case
 * Aligned with iOS AppCore DeleteTaskUseCase
 *
 * Deletes task and its associated completion logs
 */
class DeleteTaskUseCase @Inject constructor(
    private val taskRepository: TaskRepository,
    private val completionLogRepository: CompletionLogRepository
) {
    /**
     * Delete a task and its completion logs
     *
     * @param taskId Task ID to delete
     * @return Result with Unit on success
     */
    suspend operator fun invoke(taskId: String): Result<Unit> {
        return try {
            val task = taskRepository.getTaskById(taskId)
                ?: return Result.failure(
                    AppError.NotFoundError("Task", taskId)
                )

            // Delete associated completion logs first
            completionLogRepository.deleteLogsForTask(taskId)

            // Delete the task
            taskRepository.deleteTask(taskId)

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(AppError.StorageError(e))
        }
    }
}
