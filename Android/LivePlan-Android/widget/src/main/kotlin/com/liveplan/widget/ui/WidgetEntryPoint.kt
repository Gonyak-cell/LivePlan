package com.liveplan.widget.ui

import com.liveplan.widget.data.WidgetDataProvider
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

/**
 * Hilt entry point for widget components
 *
 * Widgets run in a separate process and cannot use standard Hilt injection.
 * This entry point allows accessing Hilt-managed dependencies.
 */
@EntryPoint
@InstallIn(SingletonComponent::class)
interface WidgetEntryPoint {
    fun widgetDataProvider(): WidgetDataProvider
}
