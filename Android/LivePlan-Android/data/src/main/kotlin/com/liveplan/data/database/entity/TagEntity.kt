package com.liveplan.data.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.liveplan.core.model.Tag

/**
 * Room entity for Tag
 */
@Entity(tableName = "tags")
data class TagEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val colorToken: String?
) {
    fun toDomain(): Tag = Tag(
        id = id,
        name = name,
        colorToken = colorToken
    )

    companion object {
        fun fromDomain(tag: Tag): TagEntity = TagEntity(
            id = tag.id,
            name = tag.name,
            colorToken = tag.colorToken
        )
    }
}
