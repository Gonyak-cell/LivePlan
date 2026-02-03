package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import com.liveplan.core.repository.TaskRepository
import javax.inject.Inject

/**
 * Start task use case
 * Aligned with iOS AppCore StartTaskUseCase
 *
 * Transitions task workflowState to DOING (in progress)
 */
class StartTaskUseCase @Inject constructor(
    private val taskRepository: TaskRepository
) {
    /**
     * Start a task (set workflowState to DOING)
     *
     * @param taskId Task ID to start
     * @return Result with updated Task on success
     *
     * Note: If task is already DOING, returns success without modification (idempotent)
     */
    suspend operator fun invoke(taskId: String): Result<Task> {
        return try {
            val task = taskRepository.getTaskById(taskId)
                ?: return Result.failure(
                    AppError.NotFoundError("Task", taskId)
                )

            // Idempotent: already DOING -> noop
            if (task.workflowState == WorkflowState.DOING) {
                return Result.success(task)
            }

            // Cannot start a completed task
            if (task.workflowState == WorkflowState.DONE) {
                return Result.failure(
                    AppError.ValidationError("Cannot start a completed task")
                )
            }

            val updatedTask = task.copy(
                workflowState = WorkflowState.DOING,
                updatedAt = System.currentTimeMillis()
            )

            taskRepository.updateTask(updatedTask)
            Result.success(updatedTask)
        } catch (e: Exception) {
            Result.failure(AppError.StorageError(e))
        }
    }
}
