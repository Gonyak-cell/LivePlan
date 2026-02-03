package com.liveplan.shortcuts.di

import com.liveplan.shortcuts.data.ShortcutsDataProvider
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

/**
 * Hilt entry point for shortcuts module components
 *
 * Services (TileService, NotificationService) run in separate contexts
 * and cannot use standard Hilt injection.
 * This entry point allows accessing Hilt-managed dependencies.
 */
@EntryPoint
@InstallIn(SingletonComponent::class)
interface ShortcutsEntryPoint {
    fun shortcutsDataProvider(): ShortcutsDataProvider
}
