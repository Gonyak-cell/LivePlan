package com.liveplan.core.model

/**
 * Filter definition for saved views
 * Aligned with iOS AppCore FilterDefinition
 *
 * Defines conditions for filtering tasks in views
 */
data class FilterDefinition(
    /** Include only tasks in these projects (null = all) */
    val includeProjects: List<String>? = null,
    /** Include only tasks with these tags (null = all) */
    val includeTags: List<String>? = null,
    /** Include only tasks in these sections (null = all) */
    val includeSections: List<String>? = null,
    /** Maximum priority to include (e.g., P1 means P1 only) */
    val priorityAtMost: Priority? = null,
    /** Minimum priority to include (e.g., P3 means P3 and P4) */
    val priorityAtLeast: Priority? = null,
    /** Include only tasks with these workflow states (default: TODO, DOING) */
    val stateIn: Set<WorkflowState> = setOf(WorkflowState.TODO, WorkflowState.DOING),
    /** Due date range filter */
    val dueRange: DueRange = DueRange.NONE,
    /** Include recurring tasks */
    val includeRecurring: Boolean = true,
    /** Exclude blocked tasks (default: true) */
    val excludeBlocked: Boolean = true
) {
    companion object {
        /**
         * Built-in: Today filter
         */
        val TODAY = FilterDefinition(
            dueRange = DueRange.TODAY
        )

        /**
         * Built-in: Upcoming (next 7 days) filter
         */
        val UPCOMING = FilterDefinition(
            dueRange = DueRange.NEXT_7_DAYS
        )

        /**
         * Built-in: Overdue filter
         */
        val OVERDUE = FilterDefinition(
            dueRange = DueRange.OVERDUE
        )

        /**
         * Built-in: P1 (high priority) filter
         */
        val P1_ONLY = FilterDefinition(
            priorityAtMost = Priority.P1,
            priorityAtLeast = Priority.P1
        )

        /**
         * Default filter (all active tasks)
         */
        val DEFAULT = FilterDefinition()
    }
}
