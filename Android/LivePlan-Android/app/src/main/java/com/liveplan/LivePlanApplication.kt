package com.liveplan

import android.app.Application
import com.liveplan.widget.WidgetInitializer
import dagger.hilt.android.HiltAndroidApp

/**
 * LivePlan Application class
 * Required for Hilt dependency injection
 */
@HiltAndroidApp
class LivePlanApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // Initialize widget update scheduling
        WidgetInitializer.initialize(this)
    }
}
