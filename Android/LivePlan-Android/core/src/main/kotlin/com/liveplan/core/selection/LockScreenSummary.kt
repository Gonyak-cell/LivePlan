package com.liveplan.core.selection

import com.liveplan.core.model.Task

/**
 * Lock screen display summary
 * Aligned with iOS AppCore LockScreenSummary
 *
 * Output of OutstandingComputer.compute()
 */
data class LockScreenSummary(
    /**
     * Top N tasks to display (max 3 for widget)
     */
    val displayList: List<DisplayTask>,

    /**
     * Counters for summary display
     */
    val counters: Counters,

    /**
     * Metadata about the computation
     */
    val metadata: Metadata = Metadata()
) {
    /**
     * Task with display information
     */
    data class DisplayTask(
        val task: Task,
        val maskedTitle: String,
        val group: PriorityGroup
    )

    /**
     * Priority group for selection
     * Order: G1 > G2 > G3 > G4 > G5 > G6
     */
    enum class PriorityGroup {
        G1_DOING,       // workflowState = DOING
        G2_OVERDUE,     // dueAt < now
        G3_DUE_SOON,    // 0 < dueAt - now <= 24h
        G4_P1,          // priority = P1
        G5_HABIT_TODAY, // habitReset recurring, today incomplete
        G6_OTHER        // remaining
    }

    /**
     * Summary counters
     */
    data class Counters(
        val outstandingTotal: Int = 0,
        val overdueCount: Int = 0,
        val dueSoonCount: Int = 0,
        val recurringDone: Int = 0,
        val recurringTotal: Int = 0,
        val p1Count: Int = 0,
        val doingCount: Int = 0,
        val blockedCount: Int = 0
    )

    /**
     * Computation metadata
     */
    data class Metadata(
        val dateKey: String = "",
        val scope: Scope = Scope.TODAY_OVERVIEW,
        val fallbackReason: FallbackReason? = null
    )

    /**
     * Selection scope
     */
    enum class Scope {
        PINNED_PROJECT,
        TODAY_OVERVIEW
    }

    /**
     * Fallback reason when pinned scope not available
     */
    enum class FallbackReason {
        NO_PINNED_PROJECT,
        PINNED_NOT_ACTIVE
    }

    companion object {
        /**
         * Empty summary for fail-safe fallback
         */
        val EMPTY = LockScreenSummary(
            displayList = emptyList(),
            counters = Counters()
        )
    }
}
