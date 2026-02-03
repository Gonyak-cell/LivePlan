package com.liveplan.core.model

import java.util.UUID

/**
 * Completion log entry
 * Aligned with iOS AppCore CompletionLog
 *
 * Records task completion with occurrence key for recurrence support.
 *
 * @property id Unique identifier
 * @property taskId Task ID
 * @property completedAt Completion timestamp
 * @property occurrenceKey Occurrence identifier:
 *   - oneOff: "once"
 *   - habitReset: dateKey (YYYY-MM-DD)
 *   - rollover: dateKey of nextOccurrenceDueAt
 *
 * Invariant: (taskId, occurrenceKey) must be unique
 */
data class CompletionLog(
    val id: String = UUID.randomUUID().toString(),
    val taskId: String,
    val completedAt: Long = System.currentTimeMillis(),
    val occurrenceKey: String
) {
    companion object {
        /**
         * Occurrence key for one-off tasks
         */
        const val ONCE_KEY = "once"

        /**
         * Create completion log for one-off task
         */
        fun forOneOff(taskId: String): CompletionLog =
            CompletionLog(
                taskId = taskId,
                occurrenceKey = ONCE_KEY
            )

        /**
         * Create completion log for recurring task (habitReset)
         */
        fun forHabitReset(taskId: String, dateKey: String): CompletionLog =
            CompletionLog(
                taskId = taskId,
                occurrenceKey = dateKey
            )

        /**
         * Create completion log for recurring task (rollover)
         */
        fun forRollover(taskId: String, occurrenceDueDateKey: String): CompletionLog =
            CompletionLog(
                taskId = taskId,
                occurrenceKey = occurrenceDueDateKey
            )
    }
}
