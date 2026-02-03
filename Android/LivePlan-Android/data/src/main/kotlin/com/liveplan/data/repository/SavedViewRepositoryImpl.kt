package com.liveplan.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.liveplan.core.model.SavedView
import com.liveplan.core.repository.SavedViewRepository
import com.liveplan.data.datastore.model.SavedViewDto
import com.liveplan.data.datastore.model.SavedViewListDto
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

private val Context.savedViewDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "saved_views"
)

/**
 * SavedView repository implementation using DataStore
 *
 * Built-in views are always included and cannot be modified.
 * User-created views are persisted in DataStore.
 */
@Singleton
class SavedViewRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context
) : SavedViewRepository {

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    private object Keys {
        val USER_SAVED_VIEWS = stringPreferencesKey("user_saved_views")
    }

    private val builtInViews = SavedView.builtInViews()
    private val builtInViewIds = builtInViews.map { it.id }.toSet()

    override fun getAllSavedViews(): Flow<List<SavedView>> {
        return context.savedViewDataStore.data
            .catch { emit(androidx.datastore.preferences.core.emptyPreferences()) }
            .map { preferences ->
                val userViews = parseUserViews(preferences)
                builtInViews + userViews
            }
    }

    override fun getUserSavedViews(): Flow<List<SavedView>> {
        return context.savedViewDataStore.data
            .catch { emit(androidx.datastore.preferences.core.emptyPreferences()) }
            .map { preferences ->
                parseUserViews(preferences)
            }
    }

    override suspend fun getSavedViewById(id: String): SavedView? {
        // Check built-in views first
        builtInViews.find { it.id == id }?.let { return it }

        // Check user views
        var result: SavedView? = null
        context.savedViewDataStore.edit { preferences ->
            result = parseUserViews(preferences).find { it.id == id }
        }
        return result
    }

    override suspend fun addSavedView(savedView: SavedView) {
        // Cannot add views with built-in prefix
        if (savedView.id.startsWith("built-in-")) {
            return
        }

        context.savedViewDataStore.edit { preferences ->
            val currentViews = parseUserViews(preferences).toMutableList()

            // Check for duplicate ID
            if (currentViews.none { it.id == savedView.id }) {
                currentViews.add(savedView)
                preferences[Keys.USER_SAVED_VIEWS] = encodeViews(currentViews)
            }
        }
    }

    override suspend fun updateSavedView(savedView: SavedView) {
        // Cannot update built-in views
        if (savedView.id in builtInViewIds) {
            return
        }

        context.savedViewDataStore.edit { preferences ->
            val currentViews = parseUserViews(preferences).toMutableList()
            val index = currentViews.indexOfFirst { it.id == savedView.id }

            if (index >= 0) {
                currentViews[index] = savedView.copy(updatedAt = System.currentTimeMillis())
                preferences[Keys.USER_SAVED_VIEWS] = encodeViews(currentViews)
            }
        }
    }

    override suspend fun deleteSavedView(id: String) {
        // Cannot delete built-in views
        if (id in builtInViewIds) {
            return
        }

        context.savedViewDataStore.edit { preferences ->
            val currentViews = parseUserViews(preferences).filter { it.id != id }
            preferences[Keys.USER_SAVED_VIEWS] = encodeViews(currentViews)
        }
    }

    private fun parseUserViews(preferences: Preferences): List<SavedView> {
        val jsonString = preferences[Keys.USER_SAVED_VIEWS] ?: return emptyList()
        return try {
            json.decodeFromString<SavedViewListDto>(jsonString).views.map { it.toDomain() }
        } catch (e: Exception) {
            emptyList() // Fail-safe
        }
    }

    private fun encodeViews(views: List<SavedView>): String {
        val dto = SavedViewListDto(views.map { SavedViewDto.fromDomain(it) })
        return json.encodeToString(dto)
    }
}
