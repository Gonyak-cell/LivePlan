package com.liveplan.core.model

/**
 * Scope for saved views
 * Aligned with iOS AppCore SavedView.scope
 */
sealed class ViewScope {
    /** Global view across all projects */
    data object Global : ViewScope()

    /** View scoped to a specific project */
    data class Project(val projectId: String) : ViewScope()
}
