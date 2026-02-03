package com.liveplan.core.repository

import com.liveplan.core.model.Project
import kotlinx.coroutines.flow.Flow

/**
 * Project repository interface
 * Aligned with iOS AppCore ProjectRepository
 */
interface ProjectRepository {

    /**
     * Get all projects as Flow
     */
    fun getAllProjects(): Flow<List<Project>>

    /**
     * Get active projects as Flow
     */
    fun getActiveProjects(): Flow<List<Project>>

    /**
     * Get project by ID
     */
    suspend fun getProjectById(id: String): Project?

    /**
     * Add a new project
     */
    suspend fun addProject(project: Project)

    /**
     * Update an existing project
     */
    suspend fun updateProject(project: Project)

    /**
     * Delete a project by ID
     */
    suspend fun deleteProject(id: String)
}
