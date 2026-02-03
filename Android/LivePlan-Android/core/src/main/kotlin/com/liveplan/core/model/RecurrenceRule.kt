package com.liveplan.core.model

import kotlinx.serialization.Serializable
import java.time.DayOfWeek

/**
 * Recurrence rule for recurring tasks
 * Aligned with iOS AppCore RecurrenceRule
 */
@Serializable
data class RecurrenceRule(
    val kind: RecurrenceKind,
    val interval: Int = 1,
    val weekdays: Set<Int> = emptySet(), // 1=Monday, 7=Sunday (ISO-8601)
    val timeOfDayMinutes: Int? = null, // Minutes from midnight
    val anchorDateMillis: Long // Recurrence anchor point
) {
    init {
        require(interval > 0) { "interval must be positive" }
        require(kind != RecurrenceKind.WEEKLY || weekdays.isNotEmpty()) {
            "weekdays must not be empty for weekly recurrence"
        }
    }

    /**
     * Convert weekdays to DayOfWeek set
     */
    val weekdaysAsDayOfWeek: Set<DayOfWeek>
        get() = weekdays.mapNotNull { day ->
            DayOfWeek.entries.getOrNull(day - 1)
        }.toSet()

    companion object {
        /**
         * Create a daily recurrence rule
         */
        fun daily(anchorDateMillis: Long = System.currentTimeMillis()): RecurrenceRule =
            RecurrenceRule(
                kind = RecurrenceKind.DAILY,
                anchorDateMillis = anchorDateMillis
            )

        /**
         * Create a weekly recurrence rule
         */
        fun weekly(
            weekdays: Set<DayOfWeek>,
            anchorDateMillis: Long = System.currentTimeMillis()
        ): RecurrenceRule = RecurrenceRule(
            kind = RecurrenceKind.WEEKLY,
            weekdays = weekdays.map { it.value }.toSet(),
            anchorDateMillis = anchorDateMillis
        )
    }
}
