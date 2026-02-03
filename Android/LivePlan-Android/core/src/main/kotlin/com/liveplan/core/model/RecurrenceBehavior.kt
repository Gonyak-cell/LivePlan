package com.liveplan.core.model

/**
 * Recurring task behavior type
 * Aligned with iOS AppCore RecurrenceBehavior enum
 *
 * HABIT_RESET: Check or not, resets next day (display reset)
 * ROLLOVER: Incomplete stays as overdue, completion advances to next occurrence
 */
enum class RecurrenceBehavior {
    /**
     * Default for daily recurring tasks
     * Unchecked items don't accumulate - next day shows fresh
     */
    HABIT_RESET,

    /**
     * For project/work-style recurring
     * Incomplete stays as overdue until completed
     */
    ROLLOVER;

    companion object {
        val DEFAULT = HABIT_RESET
    }
}
