package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.Priority
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.RecurrenceRule
import com.liveplan.core.model.Task
import com.liveplan.core.repository.TaskRepository
import javax.inject.Inject

/**
 * Add task use case
 * Aligned with iOS AppCore AddTaskUseCase
 */
class AddTaskUseCase @Inject constructor(
    private val taskRepository: TaskRepository
) {
    /**
     * Add a new task
     *
     * @param projectId Project ID
     * @param title Task title
     * @param priority Priority (default P4)
     * @param dueAt Due date millis (optional)
     * @param recurrenceRule Recurrence rule (optional)
     * @param recurrenceBehavior Recurrence behavior (default HABIT_RESET)
     * @param sectionId Section ID (optional)
     * @param tagIds Tag IDs (optional)
     * @param note Note (optional)
     * @return Result with created Task on success
     */
    suspend operator fun invoke(
        projectId: String,
        title: String,
        priority: Priority = Priority.DEFAULT,
        dueAt: Long? = null,
        recurrenceRule: RecurrenceRule? = null,
        recurrenceBehavior: RecurrenceBehavior = RecurrenceBehavior.DEFAULT,
        sectionId: String? = null,
        tagIds: List<String> = emptyList(),
        note: String? = null
    ): Result<Task> {
        // Validate title
        val trimmedTitle = title.trim()
        if (trimmedTitle.isBlank()) {
            return Result.failure(AppError.EmptyTitleError)
        }

        return try {
            val task = Task(
                projectId = projectId,
                title = trimmedTitle,
                priority = priority,
                dueAt = dueAt,
                recurrenceRule = recurrenceRule,
                recurrenceBehavior = recurrenceBehavior,
                sectionId = sectionId,
                tagIds = tagIds,
                note = note,
                nextOccurrenceDueAt = if (recurrenceRule != null && recurrenceBehavior == RecurrenceBehavior.ROLLOVER) {
                    dueAt ?: System.currentTimeMillis()
                } else null
            )

            taskRepository.addTask(task)
            Result.success(task)
        } catch (e: Exception) {
            Result.failure(AppError.StorageError(e))
        }
    }
}
