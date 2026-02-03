package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.Priority
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.RecurrenceRule
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import com.liveplan.core.repository.TaskRepository
import javax.inject.Inject

/**
 * Update task use case
 * Aligned with iOS AppCore UpdateTaskUseCase
 *
 * Updates existing task properties
 */
class UpdateTaskUseCase @Inject constructor(
    private val taskRepository: TaskRepository
) {
    /**
     * Update a task with new values
     *
     * @param taskId Task ID to update
     * @param title New title (optional)
     * @param priority New priority (optional)
     * @param workflowState New workflow state (optional)
     * @param dueAt New due date (optional, pass null to clear)
     * @param startAt New start time (optional)
     * @param recurrenceRule New recurrence rule (optional)
     * @param recurrenceBehavior New recurrence behavior (optional)
     * @param sectionId New section ID (optional)
     * @param tagIds New tag IDs (optional)
     * @param note New note (optional)
     * @param blockedByTaskIds New dependency task IDs (optional)
     * @return Result with updated Task on success
     */
    suspend operator fun invoke(
        taskId: String,
        title: String? = null,
        priority: Priority? = null,
        workflowState: WorkflowState? = null,
        dueAt: Long? = null,
        clearDueAt: Boolean = false,
        startAt: Long? = null,
        clearStartAt: Boolean = false,
        recurrenceRule: RecurrenceRule? = null,
        clearRecurrenceRule: Boolean = false,
        recurrenceBehavior: RecurrenceBehavior? = null,
        sectionId: String? = null,
        clearSectionId: Boolean = false,
        tagIds: List<String>? = null,
        note: String? = null,
        clearNote: Boolean = false,
        blockedByTaskIds: List<String>? = null
    ): Result<Task> {
        return try {
            val existingTask = taskRepository.getTaskById(taskId)
                ?: return Result.failure(
                    AppError.NotFoundError("Task", taskId)
                )

            // Validate title if provided
            val newTitle = title?.trim()
            if (newTitle != null && newTitle.isBlank()) {
                return Result.failure(AppError.EmptyTitleError)
            }

            // Validate blockedByTaskIds
            val newBlockedByTaskIds = blockedByTaskIds ?: existingTask.blockedByTaskIds
            if (newBlockedByTaskIds.contains(taskId)) {
                return Result.failure(
                    AppError.CircularDependencyError(listOf(taskId))
                )
            }

            // Build updated task
            val updatedTask = existingTask.copy(
                title = newTitle ?: existingTask.title,
                priority = priority ?: existingTask.priority,
                workflowState = workflowState ?: existingTask.workflowState,
                dueAt = when {
                    clearDueAt -> null
                    dueAt != null -> dueAt
                    else -> existingTask.dueAt
                },
                startAt = when {
                    clearStartAt -> null
                    startAt != null -> startAt
                    else -> existingTask.startAt
                },
                recurrenceRule = when {
                    clearRecurrenceRule -> null
                    recurrenceRule != null -> recurrenceRule
                    else -> existingTask.recurrenceRule
                },
                recurrenceBehavior = recurrenceBehavior ?: existingTask.recurrenceBehavior,
                sectionId = when {
                    clearSectionId -> null
                    sectionId != null -> sectionId
                    else -> existingTask.sectionId
                },
                tagIds = tagIds ?: existingTask.tagIds,
                note = when {
                    clearNote -> null
                    note != null -> note
                    else -> existingTask.note
                },
                blockedByTaskIds = newBlockedByTaskIds,
                updatedAt = System.currentTimeMillis()
            )

            taskRepository.updateTask(updatedTask)
            Result.success(updatedTask)
        } catch (e: Exception) {
            Result.failure(AppError.StorageError(e))
        }
    }
}
