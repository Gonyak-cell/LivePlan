package com.liveplan.data.database.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.liveplan.core.model.Priority
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.RecurrenceKind
import com.liveplan.core.model.RecurrenceRule
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Room entity for Task
 */
@Entity(
    tableName = "tasks",
    foreignKeys = [
        ForeignKey(
            entity = ProjectEntity::class,
            parentColumns = ["id"],
            childColumns = ["projectId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("projectId")]
)
data class TaskEntity(
    @PrimaryKey
    val id: String,
    val projectId: String,
    val title: String,
    val sectionId: String?,
    val tagIdsJson: String, // JSON encoded List<String>
    val priority: String, // Priority.name
    val workflowState: String, // WorkflowState.name
    val startAt: Long?,
    val dueAt: Long?,
    val note: String?,
    val recurrenceRuleJson: String?, // JSON encoded RecurrenceRule
    val recurrenceBehavior: String, // RecurrenceBehavior.name
    val nextOccurrenceDueAt: Long?,
    val blockedByTaskIdsJson: String, // JSON encoded List<String>
    val createdAt: Long,
    val updatedAt: Long
) {
    fun toDomain(): Task = Task(
        id = id,
        projectId = projectId,
        title = title,
        sectionId = sectionId,
        tagIds = Json.decodeFromString(tagIdsJson),
        priority = Priority.valueOf(priority),
        workflowState = WorkflowState.valueOf(workflowState),
        startAt = startAt,
        dueAt = dueAt,
        note = note,
        recurrenceRule = recurrenceRuleJson?.let { parseRecurrenceRule(it) },
        recurrenceBehavior = RecurrenceBehavior.valueOf(recurrenceBehavior),
        nextOccurrenceDueAt = nextOccurrenceDueAt,
        blockedByTaskIds = Json.decodeFromString(blockedByTaskIdsJson),
        createdAt = createdAt,
        updatedAt = updatedAt
    )

    private fun parseRecurrenceRule(json: String): RecurrenceRule? {
        return try {
            Json.decodeFromString<RecurrenceRule>(json)
        } catch (e: Exception) {
            null
        }
    }

    companion object {
        private val json = Json { ignoreUnknownKeys = true }

        fun fromDomain(task: Task): TaskEntity = TaskEntity(
            id = task.id,
            projectId = task.projectId,
            title = task.title,
            sectionId = task.sectionId,
            tagIdsJson = json.encodeToString(task.tagIds),
            priority = task.priority.name,
            workflowState = task.workflowState.name,
            startAt = task.startAt,
            dueAt = task.dueAt,
            note = task.note,
            recurrenceRuleJson = task.recurrenceRule?.let { json.encodeToString(it) },
            recurrenceBehavior = task.recurrenceBehavior.name,
            nextOccurrenceDueAt = task.nextOccurrenceDueAt,
            blockedByTaskIdsJson = json.encodeToString(task.blockedByTaskIds),
            createdAt = task.createdAt,
            updatedAt = task.updatedAt
        )
    }
}
