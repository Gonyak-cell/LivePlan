package com.liveplan.core.model

/**
 * Due date range filter
 * Aligned with iOS AppCore FilterDefinition.dueRange
 */
enum class DueRange {
    /** Today only */
    TODAY,
    /** Next 7 days */
    NEXT_7_DAYS,
    /** Overdue tasks */
    OVERDUE,
    /** No due date filter */
    NONE
}
