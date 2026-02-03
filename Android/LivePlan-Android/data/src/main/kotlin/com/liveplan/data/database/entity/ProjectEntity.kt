package com.liveplan.data.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.liveplan.core.model.Project
import com.liveplan.core.model.ProjectStatus

/**
 * Room entity for Project
 */
@Entity(tableName = "projects")
data class ProjectEntity(
    @PrimaryKey
    val id: String,
    val title: String,
    val startDate: Long,
    val dueDate: Long?,
    val note: String?,
    val status: String, // ProjectStatus.name
    val createdAt: Long,
    val updatedAt: Long
) {
    fun toDomain(): Project = Project(
        id = id,
        title = title,
        startDate = startDate,
        dueDate = dueDate,
        note = note,
        status = ProjectStatus.valueOf(status),
        createdAt = createdAt,
        updatedAt = updatedAt
    )

    companion object {
        fun fromDomain(project: Project): ProjectEntity = ProjectEntity(
            id = project.id,
            title = project.title,
            startDate = project.startDate,
            dueDate = project.dueDate,
            note = project.note,
            status = project.status.name,
            createdAt = project.createdAt,
            updatedAt = project.updatedAt
        )
    }
}
