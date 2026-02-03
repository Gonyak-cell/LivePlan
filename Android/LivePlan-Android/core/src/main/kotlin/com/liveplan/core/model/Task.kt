package com.liveplan.core.model

import java.util.UUID

/**
 * Task entity
 * Aligned with iOS AppCore Task
 *
 * @property id Unique identifier
 * @property projectId Parent project ID (required)
 * @property title Task title (required)
 * @property sectionId Section ID (optional, null = uncategorized)
 * @property tagIds List of tag IDs (0 or more)
 * @property priority Priority level (default P4)
 * @property workflowState Workflow state for board view (default TODO)
 * @property startAt Start time (optional, for timeline/calendar)
 * @property dueAt Due time (optional, for dueSoon/overdue)
 * @property note Task note (optional, Notion-lite)
 * @property recurrenceRule Recurrence rule (null = one-off)
 * @property recurrenceBehavior Recurrence behavior (habitReset or rollover)
 * @property nextOccurrenceDueAt Next occurrence due (for rollover)
 * @property blockedByTaskIds Dependency task IDs (same project only)
 * @property createdAt Creation timestamp
 * @property updatedAt Last update timestamp
 */
data class Task(
    val id: String = UUID.randomUUID().toString(),
    val projectId: String,
    val title: String,
    val sectionId: String? = null,
    val tagIds: List<String> = emptyList(),
    val priority: Priority = Priority.DEFAULT,
    val workflowState: WorkflowState = WorkflowState.DEFAULT,
    val startAt: Long? = null,
    val dueAt: Long? = null,
    val note: String? = null,
    val recurrenceRule: RecurrenceRule? = null,
    val recurrenceBehavior: RecurrenceBehavior = RecurrenceBehavior.DEFAULT,
    val nextOccurrenceDueAt: Long? = null,
    val blockedByTaskIds: List<String> = emptyList(),
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    init {
        require(title.isNotBlank()) { "Task title must not be blank" }
        require(!blockedByTaskIds.contains(id)) { "Task cannot block itself" }
    }

    /**
     * Whether this task is recurring
     */
    val isRecurring: Boolean
        get() = recurrenceRule != null

    /**
     * Whether this task is one-off (not recurring)
     */
    val isOneOff: Boolean
        get() = recurrenceRule == null

    /**
     * Whether this task is blocked by other tasks
     */
    val isBlocked: Boolean
        get() = blockedByTaskIds.isNotEmpty()
}
