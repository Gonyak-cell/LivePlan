package com.liveplan.data.repository

import android.database.sqlite.SQLiteConstraintException
import com.liveplan.core.error.AppError
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.data.database.dao.CompletionLogDao
import com.liveplan.data.database.entity.CompletionLogEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * Completion log repository implementation using Room
 */
class CompletionLogRepositoryImpl @Inject constructor(
    private val completionLogDao: CompletionLogDao
) : CompletionLogRepository {

    override fun getAllLogs(): Flow<List<CompletionLog>> {
        return completionLogDao.getAllLogs()
            .map { entities -> entities.map { it.toDomain() } }
            .catch { emit(emptyList()) } // Fail-safe
    }

    override fun getLogsForTask(taskId: String): Flow<List<CompletionLog>> {
        return completionLogDao.getLogsForTask(taskId)
            .map { entities -> entities.map { it.toDomain() } }
            .catch { emit(emptyList()) } // Fail-safe
    }

    override suspend fun hasCompletion(taskId: String, occurrenceKey: String): Boolean {
        return completionLogDao.hasCompletion(taskId, occurrenceKey)
    }

    override suspend fun getCompletion(taskId: String, occurrenceKey: String): CompletionLog? {
        return completionLogDao.getCompletion(taskId, occurrenceKey)?.toDomain()
    }

    override suspend fun addLog(log: CompletionLog) {
        try {
            completionLogDao.insert(CompletionLogEntity.fromDomain(log))
        } catch (e: SQLiteConstraintException) {
            throw AppError.DuplicateCompletionError(log.taskId, log.occurrenceKey)
        }
    }

    override suspend fun deleteLog(id: String) {
        completionLogDao.deleteById(id)
    }

    override suspend fun deleteLogsForTask(taskId: String) {
        completionLogDao.deleteByTaskId(taskId)
    }
}
