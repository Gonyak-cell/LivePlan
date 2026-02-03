package com.liveplan.core.model

import java.util.UUID

/**
 * Saved view (filter) entity
 * Aligned with iOS AppCore SavedView
 *
 * Represents a reusable filter configuration
 */
data class SavedView(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val scope: ViewScope,
    val viewType: ViewType = ViewType.LIST,
    val definition: FilterDefinition,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    companion object {
        /**
         * Built-in views
         */
        fun builtInViews(): List<SavedView> = listOf(
            SavedView(
                id = "built-in-today",
                name = "Today",
                scope = ViewScope.Global,
                definition = FilterDefinition.TODAY
            ),
            SavedView(
                id = "built-in-upcoming",
                name = "Upcoming",
                scope = ViewScope.Global,
                definition = FilterDefinition.UPCOMING
            ),
            SavedView(
                id = "built-in-overdue",
                name = "Overdue",
                scope = ViewScope.Global,
                definition = FilterDefinition.OVERDUE
            ),
            SavedView(
                id = "built-in-p1",
                name = "P1",
                scope = ViewScope.Global,
                definition = FilterDefinition.P1_ONLY
            )
        )
    }
}
