package com.liveplan.data.datastore

import com.google.common.truth.Truth.assertThat
import com.liveplan.core.model.AppSettings
import com.liveplan.core.model.PrivacyMode
import com.liveplan.core.model.ViewType
import com.liveplan.core.selection.SelectionPolicy
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for AppSettingsDataStore
 *
 * Uses FakeAppSettingsDataStore to test the interface contract
 * and verify all settings operations work correctly.
 *
 * Tests cover:
 * - Default values when no data stored
 * - Setting and getting each preference
 * - Clear all functionality
 * - Multiple independent updates
 */
@OptIn(ExperimentalCoroutinesApi::class)
class AppSettingsDataStoreTest {

    private lateinit var dataStore: FakeAppSettingsDataStore

    @Before
    fun setUp() {
        dataStore = FakeAppSettingsDataStore()
    }

    // ─────────────────────────────────────
    // Default Values Tests
    // ─────────────────────────────────────

    @Test
    fun `settings returns default values when datastore is empty`() = runTest {
        val settings = dataStore.settings.first()

        assertThat(settings.schemaVersion).isEqualTo(AppSettings.CURRENT_SCHEMA_VERSION)
        assertThat(settings.privacyMode).isEqualTo(PrivacyMode.DEFAULT)
        assertThat(settings.pinnedProjectId).isNull()
        assertThat(settings.lockscreenSelectionMode).isEqualTo(SelectionPolicy.PINNED_FIRST)
        assertThat(settings.defaultProjectViewType).isEqualTo(ViewType.LIST)
        assertThat(settings.quickAddParsingEnabled).isTrue()
        assertThat(settings.remindersEnabled).isFalse()
    }

    // ─────────────────────────────────────
    // Privacy Mode Tests
    // ─────────────────────────────────────

    @Test
    fun `setPrivacyMode to LEVEL_0 updates privacy mode`() = runTest {
        dataStore.setPrivacyMode(PrivacyMode.LEVEL_0)

        val settings = dataStore.settings.first()
        assertThat(settings.privacyMode).isEqualTo(PrivacyMode.LEVEL_0)
    }

    @Test
    fun `setPrivacyMode to LEVEL_1 updates privacy mode`() = runTest {
        dataStore.setPrivacyMode(PrivacyMode.LEVEL_1)

        val settings = dataStore.settings.first()
        assertThat(settings.privacyMode).isEqualTo(PrivacyMode.LEVEL_1)
    }

    @Test
    fun `setPrivacyMode to LEVEL_2 persists correctly`() = runTest {
        dataStore.setPrivacyMode(PrivacyMode.LEVEL_2)

        val settings = dataStore.settings.first()
        assertThat(settings.privacyMode).isEqualTo(PrivacyMode.LEVEL_2)
    }

    // ─────────────────────────────────────
    // Pinned Project Tests
    // ─────────────────────────────────────

    @Test
    fun `setPinnedProjectId stores project id`() = runTest {
        dataStore.setPinnedProjectId("project-123")

        val settings = dataStore.settings.first()
        assertThat(settings.pinnedProjectId).isEqualTo("project-123")
    }

    @Test
    fun `setPinnedProjectId with null clears pinned project`() = runTest {
        // First set a value
        dataStore.setPinnedProjectId("project-123")
        assertThat(dataStore.settings.first().pinnedProjectId).isEqualTo("project-123")

        // Then clear it
        dataStore.setPinnedProjectId(null)

        val settings = dataStore.settings.first()
        assertThat(settings.pinnedProjectId).isNull()
    }

    @Test
    fun `setPinnedProjectId can update existing pinned project`() = runTest {
        dataStore.setPinnedProjectId("project-1")
        dataStore.setPinnedProjectId("project-2")

        val settings = dataStore.settings.first()
        assertThat(settings.pinnedProjectId).isEqualTo("project-2")
    }

    // ─────────────────────────────────────
    // Selection Policy Tests
    // ─────────────────────────────────────

    @Test
    fun `setSelectionPolicy to TODAY_OVERVIEW updates selection mode`() = runTest {
        dataStore.setSelectionPolicy(SelectionPolicy.TODAY_OVERVIEW)

        val settings = dataStore.settings.first()
        assertThat(settings.lockscreenSelectionMode).isEqualTo(SelectionPolicy.TODAY_OVERVIEW)
    }

    @Test
    fun `setSelectionPolicy to AUTO persists correctly`() = runTest {
        dataStore.setSelectionPolicy(SelectionPolicy.AUTO)

        val settings = dataStore.settings.first()
        assertThat(settings.lockscreenSelectionMode).isEqualTo(SelectionPolicy.AUTO)
    }

    @Test
    fun `setSelectionPolicy to PINNED_FIRST persists correctly`() = runTest {
        // First change to something else
        dataStore.setSelectionPolicy(SelectionPolicy.TODAY_OVERVIEW)
        // Then back to PINNED_FIRST
        dataStore.setSelectionPolicy(SelectionPolicy.PINNED_FIRST)

        val settings = dataStore.settings.first()
        assertThat(settings.lockscreenSelectionMode).isEqualTo(SelectionPolicy.PINNED_FIRST)
    }

    // ─────────────────────────────────────
    // Default View Type Tests
    // ─────────────────────────────────────

    @Test
    fun `setDefaultViewType to BOARD updates view type`() = runTest {
        dataStore.setDefaultViewType(ViewType.BOARD)

        val settings = dataStore.settings.first()
        assertThat(settings.defaultProjectViewType).isEqualTo(ViewType.BOARD)
    }

    @Test
    fun `setDefaultViewType to CALENDAR persists correctly`() = runTest {
        dataStore.setDefaultViewType(ViewType.CALENDAR)

        val settings = dataStore.settings.first()
        assertThat(settings.defaultProjectViewType).isEqualTo(ViewType.CALENDAR)
    }

    @Test
    fun `setDefaultViewType to LIST persists correctly`() = runTest {
        dataStore.setDefaultViewType(ViewType.BOARD)
        dataStore.setDefaultViewType(ViewType.LIST)

        val settings = dataStore.settings.first()
        assertThat(settings.defaultProjectViewType).isEqualTo(ViewType.LIST)
    }

    // ─────────────────────────────────────
    // Quick Add Parsing Tests
    // ─────────────────────────────────────

    @Test
    fun `setQuickAddParsing false disables parsing`() = runTest {
        dataStore.setQuickAddParsing(false)

        val settings = dataStore.settings.first()
        assertThat(settings.quickAddParsingEnabled).isFalse()
    }

    @Test
    fun `setQuickAddParsing true enables parsing`() = runTest {
        // First disable
        dataStore.setQuickAddParsing(false)
        // Then enable
        dataStore.setQuickAddParsing(true)

        val settings = dataStore.settings.first()
        assertThat(settings.quickAddParsingEnabled).isTrue()
    }

    // ─────────────────────────────────────
    // Reminders Tests
    // ─────────────────────────────────────

    @Test
    fun `setRemindersEnabled true enables reminders`() = runTest {
        dataStore.setRemindersEnabled(true)

        val settings = dataStore.settings.first()
        assertThat(settings.remindersEnabled).isTrue()
    }

    @Test
    fun `setRemindersEnabled false disables reminders`() = runTest {
        // First enable
        dataStore.setRemindersEnabled(true)
        // Then disable
        dataStore.setRemindersEnabled(false)

        val settings = dataStore.settings.first()
        assertThat(settings.remindersEnabled).isFalse()
    }

    // ─────────────────────────────────────
    // Schema Version Tests
    // ─────────────────────────────────────

    @Test
    fun `setSchemaVersion updates version`() = runTest {
        dataStore.setSchemaVersion(2)

        val settings = dataStore.settings.first()
        assertThat(settings.schemaVersion).isEqualTo(2)
    }

    @Test
    fun `getCurrentSchemaVersion returns stored version`() = runTest {
        dataStore.setSchemaVersion(3)

        val version = dataStore.getCurrentSchemaVersion()
        assertThat(version).isEqualTo(3)
    }

    @Test
    fun `getCurrentSchemaVersion returns default when not set`() = runTest {
        val version = dataStore.getCurrentSchemaVersion()
        assertThat(version).isEqualTo(AppSettings.CURRENT_SCHEMA_VERSION)
    }

    // ─────────────────────────────────────
    // Clear All Tests
    // ─────────────────────────────────────

    @Test
    fun `clearAll resets all settings to defaults`() = runTest {
        // Set non-default values
        dataStore.setPrivacyMode(PrivacyMode.LEVEL_2)
        dataStore.setPinnedProjectId("project-123")
        dataStore.setSelectionPolicy(SelectionPolicy.TODAY_OVERVIEW)
        dataStore.setDefaultViewType(ViewType.BOARD)
        dataStore.setQuickAddParsing(false)
        dataStore.setRemindersEnabled(true)
        dataStore.setSchemaVersion(5)

        // Clear all
        dataStore.clearAll()

        // Verify defaults
        val settings = dataStore.settings.first()
        assertThat(settings.schemaVersion).isEqualTo(AppSettings.CURRENT_SCHEMA_VERSION)
        assertThat(settings.privacyMode).isEqualTo(PrivacyMode.DEFAULT)
        assertThat(settings.pinnedProjectId).isNull()
        assertThat(settings.lockscreenSelectionMode).isEqualTo(SelectionPolicy.PINNED_FIRST)
        assertThat(settings.defaultProjectViewType).isEqualTo(ViewType.LIST)
        assertThat(settings.quickAddParsingEnabled).isTrue()
        assertThat(settings.remindersEnabled).isFalse()
    }

    // ─────────────────────────────────────
    // Multiple Updates Tests
    // ─────────────────────────────────────

    @Test
    fun `multiple settings can be updated independently`() = runTest {
        dataStore.setPrivacyMode(PrivacyMode.LEVEL_0)
        dataStore.setPinnedProjectId("project-1")
        dataStore.setDefaultViewType(ViewType.CALENDAR)

        val settings = dataStore.settings.first()

        assertThat(settings.privacyMode).isEqualTo(PrivacyMode.LEVEL_0)
        assertThat(settings.pinnedProjectId).isEqualTo("project-1")
        assertThat(settings.defaultProjectViewType).isEqualTo(ViewType.CALENDAR)
        // Unchanged settings should be default
        assertThat(settings.lockscreenSelectionMode).isEqualTo(SelectionPolicy.PINNED_FIRST)
        assertThat(settings.quickAddParsingEnabled).isTrue()
        assertThat(settings.remindersEnabled).isFalse()
    }

    @Test
    fun `settings flow emits updated values`() = runTest {
        // Initial value
        val initialSettings = dataStore.settings.first()
        assertThat(initialSettings.privacyMode).isEqualTo(PrivacyMode.DEFAULT)

        // Update
        dataStore.setPrivacyMode(PrivacyMode.LEVEL_2)

        // New value should be emitted
        val updatedSettings = dataStore.settings.first()
        assertThat(updatedSettings.privacyMode).isEqualTo(PrivacyMode.LEVEL_2)
    }
}

/**
 * Fake implementation of IAppSettingsDataStore for testing
 * Uses in-memory storage with MutableStateFlow
 */
class FakeAppSettingsDataStore : IAppSettingsDataStore {

    private val _settings = MutableStateFlow(AppSettings.DEFAULT)

    override val settings: Flow<AppSettings> = _settings

    override suspend fun setPrivacyMode(mode: PrivacyMode) {
        _settings.update { it.copy(privacyMode = mode) }
    }

    override suspend fun setPinnedProjectId(projectId: String?) {
        _settings.update { it.copy(pinnedProjectId = projectId) }
    }

    override suspend fun setSelectionPolicy(policy: SelectionPolicy) {
        _settings.update { it.copy(lockscreenSelectionMode = policy) }
    }

    override suspend fun setDefaultViewType(viewType: ViewType) {
        _settings.update { it.copy(defaultProjectViewType = viewType) }
    }

    override suspend fun setQuickAddParsing(enabled: Boolean) {
        _settings.update { it.copy(quickAddParsingEnabled = enabled) }
    }

    override suspend fun setRemindersEnabled(enabled: Boolean) {
        _settings.update { it.copy(remindersEnabled = enabled) }
    }

    override suspend fun setSchemaVersion(version: Int) {
        _settings.update { it.copy(schemaVersion = version) }
    }

    override suspend fun getCurrentSchemaVersion(): Int {
        return _settings.value.schemaVersion
    }

    override suspend fun clearAll() {
        _settings.value = AppSettings.DEFAULT
    }
}
