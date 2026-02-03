package com.liveplan.data.database.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.liveplan.core.model.CompletionLog

/**
 * Room entity for CompletionLog
 */
@Entity(
    tableName = "completion_logs",
    foreignKeys = [
        ForeignKey(
            entity = TaskEntity::class,
            parentColumns = ["id"],
            childColumns = ["taskId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index("taskId"),
        Index(value = ["taskId", "occurrenceKey"], unique = true)
    ]
)
data class CompletionLogEntity(
    @PrimaryKey
    val id: String,
    val taskId: String,
    val completedAt: Long,
    val occurrenceKey: String
) {
    fun toDomain(): CompletionLog = CompletionLog(
        id = id,
        taskId = taskId,
        completedAt = completedAt,
        occurrenceKey = occurrenceKey
    )

    companion object {
        fun fromDomain(log: CompletionLog): CompletionLogEntity = CompletionLogEntity(
            id = log.id,
            taskId = log.taskId,
            completedAt = log.completedAt,
            occurrenceKey = log.occurrenceKey
        )
    }
}
