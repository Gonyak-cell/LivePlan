package com.liveplan.core.model

import java.util.UUID

/**
 * Tag entity - many-to-many classification for tasks
 * Aligned with iOS AppCore Tag
 *
 * @property id Unique identifier
 * @property name Tag name
 * @property colorToken Optional color token (Phase 2)
 */
data class Tag(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val colorToken: String? = null
) {
    init {
        require(name.isNotBlank()) { "Tag name must not be blank" }
    }
}
