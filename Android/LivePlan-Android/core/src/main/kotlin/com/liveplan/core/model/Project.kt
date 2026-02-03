package com.liveplan.core.model

import java.util.UUID

/**
 * Project entity
 * Aligned with iOS AppCore Project
 *
 * @property id Unique identifier
 * @property title Project title (required)
 * @property startDate Start date in millis (required)
 * @property dueDate Due date in millis (optional)
 * @property note Project note/description (optional, Notion-lite)
 * @property status Project status
 * @property createdAt Creation timestamp
 * @property updatedAt Last update timestamp
 */
data class Project(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val startDate: Long,
    val dueDate: Long? = null,
    val note: String? = null,
    val status: ProjectStatus = ProjectStatus.ACTIVE,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    init {
        require(title.isNotBlank()) { "Project title must not be blank" }
        require(dueDate == null || dueDate >= startDate) {
            "dueDate must be >= startDate"
        }
    }

    val isActive: Boolean
        get() = status == ProjectStatus.ACTIVE
}
