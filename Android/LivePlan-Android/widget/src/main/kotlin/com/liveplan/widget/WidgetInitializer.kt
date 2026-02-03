package com.liveplan.widget

import android.content.Context
import com.liveplan.widget.worker.WidgetUpdateWorker

/**
 * Widget initialization utilities
 *
 * Call these methods from the Application class to set up widget refresh.
 */
object WidgetInitializer {

    /**
     * Initialize widget update scheduling
     *
     * Should be called from Application.onCreate()
     *
     * @param context Application context
     */
    fun initialize(context: Context) {
        // Schedule periodic widget updates
        WidgetUpdateWorker.schedule(context)
    }

    /**
     * Trigger immediate widget refresh
     *
     * Call this when data changes that should be reflected in widgets.
     *
     * @param context Application context
     */
    suspend fun refreshWidgets(context: Context) {
        WidgetUpdateWorker.updateNow(context)
    }
}
