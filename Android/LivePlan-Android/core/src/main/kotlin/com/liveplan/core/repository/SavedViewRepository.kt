package com.liveplan.core.repository

import com.liveplan.core.model.SavedView
import kotlinx.coroutines.flow.Flow

/**
 * SavedView (filter) repository interface
 */
interface SavedViewRepository {

    /**
     * Get all saved views as Flow (includes built-in views)
     */
    fun getAllSavedViews(): Flow<List<SavedView>>

    /**
     * Get user-created saved views only (excludes built-in)
     */
    fun getUserSavedViews(): Flow<List<SavedView>>

    /**
     * Get saved view by ID
     */
    suspend fun getSavedViewById(id: String): SavedView?

    /**
     * Add a new saved view
     * Note: Cannot add views with "built-in-" prefix ID
     */
    suspend fun addSavedView(savedView: SavedView)

    /**
     * Update an existing saved view
     * Note: Cannot update built-in views
     */
    suspend fun updateSavedView(savedView: SavedView)

    /**
     * Delete a saved view by ID
     * Note: Cannot delete built-in views
     */
    suspend fun deleteSavedView(id: String)
}
