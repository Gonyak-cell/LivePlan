package com.liveplan.core.repository

import com.liveplan.core.model.Section
import kotlinx.coroutines.flow.Flow

/**
 * Section repository interface
 */
interface SectionRepository {

    /**
     * Get sections by project ID as Flow
     */
    fun getSectionsByProject(projectId: String): Flow<List<Section>>

    /**
     * Get section by ID
     */
    suspend fun getSectionById(id: String): Section?

    /**
     * Add a new section
     */
    suspend fun addSection(section: Section)

    /**
     * Update an existing section
     */
    suspend fun updateSection(section: Section)

    /**
     * Delete a section by ID
     * Note: Tasks in this section become uncategorized (sectionId = null)
     */
    suspend fun deleteSection(id: String)
}
