package com.liveplan.widget.worker

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.liveplan.widget.ui.MediumWidget
import com.liveplan.widget.ui.SmallWidget
import java.util.concurrent.TimeUnit

/**
 * WorkManager worker for periodic widget updates
 *
 * Updates all LivePlan widgets every 30 minutes.
 * Aligned with iOS widget refresh strategy (though iOS has different constraints).
 */
class WidgetUpdateWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            // Update all Medium widgets
            MediumWidget().updateAll(context)

            // Update all Small widgets
            SmallWidget().updateAll(context)

            Result.success()
        } catch (e: Exception) {
            // Retry on failure
            Result.retry()
        }
    }

    companion object {
        private const val WORK_NAME = "LivePlanWidgetUpdate"
        private const val REFRESH_INTERVAL_MINUTES = 30L

        /**
         * Schedule periodic widget updates
         *
         * @param context Application context
         */
        fun schedule(context: Context) {
            val workRequest = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                REFRESH_INTERVAL_MINUTES,
                TimeUnit.MINUTES
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                workRequest
            )
        }

        /**
         * Cancel scheduled widget updates
         *
         * @param context Application context
         */
        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }

        /**
         * Trigger immediate widget update
         *
         * @param context Application context
         */
        suspend fun updateNow(context: Context) {
            try {
                MediumWidget().updateAll(context)
                SmallWidget().updateAll(context)
            } catch (e: Exception) {
                // Fail silently - widget update is non-critical
            }
        }
    }
}
