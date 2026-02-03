package com.liveplan.data.database.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.liveplan.core.model.Section

/**
 * Room entity for Section
 */
@Entity(
    tableName = "sections",
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
data class SectionEntity(
    @PrimaryKey
    val id: String,
    val projectId: String,
    val title: String,
    val orderIndex: Int
) {
    fun toDomain(): Section = Section(
        id = id,
        projectId = projectId,
        title = title,
        orderIndex = orderIndex
    )

    companion object {
        fun fromDomain(section: Section): SectionEntity = SectionEntity(
            id = section.id,
            projectId = section.projectId,
            title = section.title,
            orderIndex = section.orderIndex
        )
    }
}
