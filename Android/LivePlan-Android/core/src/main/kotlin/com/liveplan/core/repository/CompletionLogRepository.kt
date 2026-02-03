package com.liveplan.core.repository

import com.liveplan.core.model.CompletionLog
import kotlinx.coroutines.flow.Flow

/**
 * Completion log repository interface
 * Aligned with iOS AppCore CompletionLogRepository
 */
interface CompletionLogRepository {

    /**
     * Get all completion logs as Flow
     */
    fun getAllLogs(): Flow<List<CompletionLog>>

    /**
     * Get completion logs for a task
     */
    fun getLogsForTask(taskId: String): Flow<List<CompletionLog>>

    /**
     * Check if completion exists for task and occurrence
     */
    suspend fun hasCompletion(taskId: String, occurrenceKey: String): Boolean

    /**
     * Get completion log by task and occurrence
     */
    suspend fun getCompletion(taskId: String, occurrenceKey: String): CompletionLog?

    /**
     * Add a completion log
     * @throws AppError.DuplicateCompletionError if already exists
     */
    suspend fun addLog(log: CompletionLog)

    /**
     * Delete a completion log by ID
     */
    suspend fun deleteLog(id: String)

    /**
     * Delete all logs for a task
     */
    suspend fun deleteLogsForTask(taskId: String)
}
