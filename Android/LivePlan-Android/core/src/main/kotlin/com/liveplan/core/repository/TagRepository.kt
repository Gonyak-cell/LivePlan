package com.liveplan.core.repository

import com.liveplan.core.model.Tag
import kotlinx.coroutines.flow.Flow

/**
 * Tag repository interface
 */
interface TagRepository {

    /**
     * Get all tags as Flow
     */
    fun getAllTags(): Flow<List<Tag>>

    /**
     * Get tag by ID
     */
    suspend fun getTagById(id: String): Tag?

    /**
     * Get tag by name (case-insensitive recommended)
     */
    suspend fun getTagByName(name: String): Tag?

    /**
     * Add a new tag
     */
    suspend fun addTag(tag: Tag)

    /**
     * Update an existing tag
     */
    suspend fun updateTag(tag: Tag)

    /**
     * Delete a tag by ID
     * Note: Task.tagIds references are not automatically removed
     */
    suspend fun deleteTag(id: String)
}
