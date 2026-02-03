package com.liveplan.core.repository

import com.liveplan.core.model.Task
import kotlinx.coroutines.flow.Flow

/**
 * Task repository interface
 * Aligned with iOS AppCore TaskRepository
 */
interface TaskRepository {

    /**
     * Get all tasks as Flow
     */
    fun getAllTasks(): Flow<List<Task>>

    /**
     * Get tasks by project ID as Flow
     */
    fun getTasksByProject(projectId: String): Flow<List<Task>>

    /**
     * Get task by ID
     */
    suspend fun getTaskById(id: String): Task?

    /**
     * Add a new task
     */
    suspend fun addTask(task: Task)

    /**
     * Update an existing task
     */
    suspend fun updateTask(task: Task)

    /**
     * Delete a task by ID
     */
    suspend fun deleteTask(id: String)

    /**
     * Get tasks by IDs
     */
    suspend fun getTasksByIds(ids: List<String>): List<Task>
}
