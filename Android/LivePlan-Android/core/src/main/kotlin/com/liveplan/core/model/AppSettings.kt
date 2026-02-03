package com.liveplan.core.model

import com.liveplan.core.selection.SelectionPolicy

/**
 * Application settings
 * Aligned with iOS AppCore AppSettings
 *
 * @property schemaVersion Data schema version for migrations
 * @property privacyMode Privacy mode for lock screen display
 * @property pinnedProjectId Pinned (representative) project ID
 * @property lockscreenSelectionMode Lock screen selection policy
 * @property defaultProjectViewType Default view type for projects
 * @property quickAddParsingEnabled Enable quick add text parsing
 * @property remindersEnabled Enable reminders (Phase 2.1)
 */
data class AppSettings(
    val schemaVersion: Int = CURRENT_SCHEMA_VERSION,
    val privacyMode: PrivacyMode = PrivacyMode.DEFAULT,
    val pinnedProjectId: String? = null,
    val lockscreenSelectionMode: SelectionPolicy = SelectionPolicy.PINNED_FIRST,
    val defaultProjectViewType: ViewType = ViewType.LIST,
    val quickAddParsingEnabled: Boolean = true,
    val remindersEnabled: Boolean = false
) {
    companion object {
        /**
         * Current schema version
         * Increment when data model changes require migration
         */
        const val CURRENT_SCHEMA_VERSION = 1

        /**
         * Default settings
         */
        val DEFAULT = AppSettings()
    }

    /**
     * Check if pinned project is set
     */
    val hasPinnedProject: Boolean
        get() = pinnedProjectId != null

    /**
     * Copy with new pinned project
     */
    fun withPinnedProject(projectId: String?): AppSettings =
        copy(pinnedProjectId = projectId)

    /**
     * Copy with new privacy mode
     */
    fun withPrivacyMode(mode: PrivacyMode): AppSettings =
        copy(privacyMode = mode)

    /**
     * Copy with new selection mode
     */
    fun withSelectionMode(mode: SelectionPolicy): AppSettings =
        copy(lockscreenSelectionMode = mode)

    /**
     * Copy with new default view type
     */
    fun withDefaultViewType(viewType: ViewType): AppSettings =
        copy(defaultProjectViewType = viewType)

    /**
     * Copy with quick add parsing toggle
     */
    fun withQuickAddParsing(enabled: Boolean): AppSettings =
        copy(quickAddParsingEnabled = enabled)
}
