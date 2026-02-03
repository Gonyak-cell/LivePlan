package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.core.util.DateKeyUtil
import javax.inject.Inject

/**
 * Uncomplete task use case
 * Aligned with iOS AppCore UncompleteTaskUseCase
 *
 * Removes completion log to "undo" a task completion
 */
class UncompleteTaskUseCase @Inject constructor(
    private val taskRepository: TaskRepository,
    private val completionLogRepository: CompletionLogRepository
) {
    /**
     * Uncomplete a task (remove completion log)
     *
     * @param taskId Task ID to uncomplete
     * @param dateKey Current dateKey (for recurring tasks, default: today)
     * @return Result with removed CompletionLog on success
     */
    suspend operator fun invoke(
        taskId: String,
        dateKey: String = DateKeyUtil.today()
    ): Result<CompletionLog> {
        return try {
            val task = taskRepository.getTaskById(taskId)
                ?: return Result.failure(
                    AppError.NotFoundError("Task", taskId)
                )

            // Determine occurrence key
            val occurrenceKey = if (task.isOneOff) {
                CompletionLog.ONCE_KEY
            } else {
                when (task.recurrenceBehavior) {
                    RecurrenceBehavior.HABIT_RESET -> dateKey
                    RecurrenceBehavior.ROLLOVER -> {
                        task.nextOccurrenceDueAt?.let {
                            DateKeyUtil.fromMillis(it)
                        } ?: dateKey
                    }
                }
            }

            // Find and delete the completion log
            val log = completionLogRepository.getCompletion(taskId, occurrenceKey)
                ?: return Result.failure(
                    AppError.NotFoundError("CompletionLog", "$taskId:$occurrenceKey")
                )

            completionLogRepository.deleteLog(log.id)

            // For rollover tasks, revert nextOccurrenceDueAt if needed
            if (task.isRecurring && task.recurrenceBehavior == RecurrenceBehavior.ROLLOVER) {
                revertRolloverTask(task)
            }

            Result.success(log)
        } catch (e: Exception) {
            Result.failure(AppError.StorageError(e))
        }
    }

    private suspend fun revertRolloverTask(task: com.liveplan.core.model.Task) {
        // Revert to previous occurrence (go back one day for now)
        // TODO: Calculate previous occurrence based on recurrence rule
        val previousDue = task.nextOccurrenceDueAt?.let {
            it - 24 * 60 * 60 * 1000L
        }

        if (previousDue != null) {
            taskRepository.updateTask(
                task.copy(
                    nextOccurrenceDueAt = previousDue,
                    updatedAt = System.currentTimeMillis()
                )
            )
        }
    }
}
