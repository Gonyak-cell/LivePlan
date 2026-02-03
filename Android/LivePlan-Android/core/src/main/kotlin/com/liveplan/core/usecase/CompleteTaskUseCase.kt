package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.Task
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.core.util.DateKeyUtil
import com.liveplan.core.util.RecurrenceCalculator
import javax.inject.Inject

/**
 * Complete task use case
 * Aligned with iOS AppCore CompleteTaskUseCase
 *
 * Handles both one-off and recurring task completion
 */
class CompleteTaskUseCase @Inject constructor(
    private val taskRepository: TaskRepository,
    private val completionLogRepository: CompletionLogRepository
) {
    /**
     * Complete a task
     *
     * @param taskId Task ID to complete
     * @param dateKey Current dateKey (for recurring tasks)
     * @return Result with CompletionLog on success
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

            val log = createCompletionLog(task, dateKey)

            // Check for duplicate
            if (completionLogRepository.hasCompletion(taskId, log.occurrenceKey)) {
                return Result.failure(
                    AppError.DuplicateCompletionError(taskId, log.occurrenceKey)
                )
            }

            completionLogRepository.addLog(log)

            // Update task for rollover behavior
            if (task.isRecurring && task.recurrenceBehavior == RecurrenceBehavior.ROLLOVER) {
                advanceRolloverTask(task)
            }

            Result.success(log)
        } catch (e: Exception) {
            Result.failure(AppError.StorageError(e))
        }
    }

    private fun createCompletionLog(task: Task, dateKey: String): CompletionLog {
        return if (task.isOneOff) {
            CompletionLog.forOneOff(task.id)
        } else {
            when (task.recurrenceBehavior) {
                RecurrenceBehavior.HABIT_RESET -> {
                    CompletionLog.forHabitReset(task.id, dateKey)
                }
                RecurrenceBehavior.ROLLOVER -> {
                    val occurrenceKey = task.nextOccurrenceDueAt?.let {
                        DateKeyUtil.fromMillis(it)
                    } ?: dateKey
                    CompletionLog.forRollover(task.id, occurrenceKey)
                }
            }
        }
    }

    private suspend fun advanceRolloverTask(task: Task) {
        val recurrenceRule = task.recurrenceRule
            ?: return // No recurrence rule, nothing to advance

        val currentOccurrence = task.nextOccurrenceDueAt
            ?: System.currentTimeMillis()

        val nextDue = RecurrenceCalculator.calculateNextOccurrence(
            rule = recurrenceRule,
            currentOccurrence = currentOccurrence
        )

        taskRepository.updateTask(
            task.copy(
                nextOccurrenceDueAt = nextDue,
                updatedAt = System.currentTimeMillis()
            )
        )
    }
}
