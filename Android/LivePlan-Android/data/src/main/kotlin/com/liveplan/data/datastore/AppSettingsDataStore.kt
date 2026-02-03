package com.liveplan.data.datastore

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.liveplan.core.model.AppSettings
import com.liveplan.core.model.PrivacyMode
import com.liveplan.core.model.ViewType
import com.liveplan.core.selection.SelectionPolicy
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(
    name = "app_settings"
)

/**
 * Interface for app settings data store operations
 * Extracted for testability
 */
interface IAppSettingsDataStore {
    val settings: Flow<AppSettings>
    suspend fun setPrivacyMode(mode: PrivacyMode)
    suspend fun setPinnedProjectId(projectId: String?)
    suspend fun setSelectionPolicy(policy: SelectionPolicy)
    suspend fun setDefaultViewType(viewType: ViewType)
    suspend fun setQuickAddParsing(enabled: Boolean)
    suspend fun setRemindersEnabled(enabled: Boolean)
    suspend fun setSchemaVersion(version: Int)
    suspend fun getCurrentSchemaVersion(): Int
    suspend fun clearAll()
}

/**
 * DataStore-based app settings repository
 */
@Singleton
class AppSettingsDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) : IAppSettingsDataStore {

    internal object Keys {
        val SCHEMA_VERSION = intPreferencesKey("schema_version")
        val PRIVACY_MODE = stringPreferencesKey("privacy_mode")
        val PINNED_PROJECT_ID = stringPreferencesKey("pinned_project_id")
        val SELECTION_POLICY = stringPreferencesKey("selection_policy")
        val DEFAULT_VIEW_TYPE = stringPreferencesKey("default_view_type")
        val QUICK_ADD_PARSING = booleanPreferencesKey("quick_add_parsing")
        val REMINDERS_ENABLED = booleanPreferencesKey("reminders_enabled")
    }

    /**
     * Get app settings as Flow
     */
    override val settings: Flow<AppSettings> = context.dataStore.data
        .catch { emit(androidx.datastore.preferences.core.emptyPreferences()) }
        .map { preferences ->
            AppSettings(
                schemaVersion = preferences[Keys.SCHEMA_VERSION]
                    ?: AppSettings.CURRENT_SCHEMA_VERSION,
                privacyMode = preferences[Keys.PRIVACY_MODE]?.let {
                    try { PrivacyMode.valueOf(it) } catch (e: Exception) { PrivacyMode.DEFAULT }
                } ?: PrivacyMode.DEFAULT,
                pinnedProjectId = preferences[Keys.PINNED_PROJECT_ID],
                lockscreenSelectionMode = preferences[Keys.SELECTION_POLICY]?.let {
                    try { SelectionPolicy.valueOf(it) } catch (e: Exception) { SelectionPolicy.PINNED_FIRST }
                } ?: SelectionPolicy.PINNED_FIRST,
                defaultProjectViewType = preferences[Keys.DEFAULT_VIEW_TYPE]?.let {
                    try { ViewType.valueOf(it) } catch (e: Exception) { ViewType.LIST }
                } ?: ViewType.LIST,
                quickAddParsingEnabled = preferences[Keys.QUICK_ADD_PARSING] ?: true,
                remindersEnabled = preferences[Keys.REMINDERS_ENABLED] ?: false
            )
        }

    /**
     * Update privacy mode
     */
    override suspend fun setPrivacyMode(mode: PrivacyMode) {
        context.dataStore.edit { preferences ->
            preferences[Keys.PRIVACY_MODE] = mode.name
        }
    }

    /**
     * Update pinned project ID
     */
    override suspend fun setPinnedProjectId(projectId: String?) {
        context.dataStore.edit { preferences ->
            if (projectId != null) {
                preferences[Keys.PINNED_PROJECT_ID] = projectId
            } else {
                preferences.remove(Keys.PINNED_PROJECT_ID)
            }
        }
    }

    /**
     * Update selection policy
     */
    override suspend fun setSelectionPolicy(policy: SelectionPolicy) {
        context.dataStore.edit { preferences ->
            preferences[Keys.SELECTION_POLICY] = policy.name
        }
    }

    /**
     * Update default project view type
     */
    override suspend fun setDefaultViewType(viewType: ViewType) {
        context.dataStore.edit { preferences ->
            preferences[Keys.DEFAULT_VIEW_TYPE] = viewType.name
        }
    }

    /**
     * Update quick add parsing setting
     */
    override suspend fun setQuickAddParsing(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[Keys.QUICK_ADD_PARSING] = enabled
        }
    }

    /**
     * Update reminders setting
     */
    override suspend fun setRemindersEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[Keys.REMINDERS_ENABLED] = enabled
        }
    }

    /**
     * Update schema version (for migrations)
     */
    override suspend fun setSchemaVersion(version: Int) {
        context.dataStore.edit { preferences ->
            preferences[Keys.SCHEMA_VERSION] = version
        }
    }

    /**
     * Get current schema version synchronously (for migration checks)
     */
    override suspend fun getCurrentSchemaVersion(): Int {
        var version = AppSettings.CURRENT_SCHEMA_VERSION
        context.dataStore.edit { preferences ->
            version = preferences[Keys.SCHEMA_VERSION] ?: AppSettings.CURRENT_SCHEMA_VERSION
        }
        return version
    }

    /**
     * Clear all settings (for testing/reset)
     */
    override suspend fun clearAll() {
        context.dataStore.edit { preferences ->
            preferences.clear()
        }
    }
}
