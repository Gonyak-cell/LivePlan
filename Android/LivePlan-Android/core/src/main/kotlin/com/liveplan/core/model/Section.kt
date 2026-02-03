package com.liveplan.core.model

import java.util.UUID

/**
 * Section entity - groups tasks within a project
 * Aligned with iOS AppCore Section
 *
 * @property id Unique identifier
 * @property projectId Parent project ID (required)
 * @property title Section title
 * @property orderIndex Display order (optional)
 */
data class Section(
    val id: String = UUID.randomUUID().toString(),
    val projectId: String,
    val title: String,
    val orderIndex: Int = 0
) {
    init {
        require(title.isNotBlank()) { "Section title must not be blank" }
    }
}
