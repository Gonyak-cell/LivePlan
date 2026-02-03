package com.liveplan.data.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.liveplan.data.database.entity.CompletionLogEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface CompletionLogDao {

    @Query("SELECT * FROM completion_logs ORDER BY completedAt DESC")
    fun getAllLogs(): Flow<List<CompletionLogEntity>>

    @Query("SELECT * FROM completion_logs WHERE taskId = :taskId ORDER BY completedAt DESC")
    fun getLogsForTask(taskId: String): Flow<List<CompletionLogEntity>>

    @Query("SELECT * FROM completion_logs WHERE taskId = :taskId AND occurrenceKey = :occurrenceKey LIMIT 1")
    suspend fun getCompletion(taskId: String, occurrenceKey: String): CompletionLogEntity?

    @Query("SELECT EXISTS(SELECT 1 FROM completion_logs WHERE taskId = :taskId AND occurrenceKey = :occurrenceKey)")
    suspend fun hasCompletion(taskId: String, occurrenceKey: String): Boolean

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(log: CompletionLogEntity)

    @Query("DELETE FROM completion_logs WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM completion_logs WHERE taskId = :taskId")
    suspend fun deleteByTaskId(taskId: String)
}
