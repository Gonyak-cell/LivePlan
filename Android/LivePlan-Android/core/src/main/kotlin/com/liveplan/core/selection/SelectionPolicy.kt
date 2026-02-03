package com.liveplan.core.selection

/**
 * Lock screen selection policy
 * Aligned with iOS AppCore selectionPolicy
 */
enum class SelectionPolicy {
    /**
     * Prefer pinned project, fallback to today overview
     */
    PINNED_FIRST,

    /**
     * Always use today overview (all active projects)
     */
    TODAY_OVERVIEW,

    /**
     * Auto: use pinned if set, otherwise today overview
     */
    AUTO
}
