package com.liveplan.shortcuts.notification

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.widget.Toast
import androidx.core.app.NotificationCompat
import com.liveplan.core.model.PrivacyMode
import com.liveplan.shortcuts.R
import com.liveplan.shortcuts.data.ShortcutResult
import com.liveplan.shortcuts.data.ShortcutsDataProvider
import com.liveplan.shortcuts.di.ShortcutsEntryPoint
import dagger.hilt.android.EntryPointAccessors
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Ongoing Notification Service for LivePlan
 *
 * This service shows a persistent notification with the current task progress,
 * similar to iOS Live Activity. It provides quick access to complete the next task.
 *
 * Features:
 * - Shows current outstanding task count
 * - Displays next task title (respecting privacy mode)
 * - Complete action button
 * - Dismiss action button
 * - Auto-updates when tasks change
 *
 * Aligns with iOS Live Activity behavior while respecting Android notification guidelines.
 */
class LivePlanNotificationService : Service() {

    private val serviceScope = CoroutineScope(Dispatchers.Main + Job())
    private lateinit var dataProvider: ShortcutsDataProvider
    private lateinit var notificationManager: NotificationManager

    override fun onCreate() {
        super.onCreate()

        // Initialize Hilt dependencies
        val entryPoint = EntryPointAccessors.fromApplication(
            applicationContext,
            ShortcutsEntryPoint::class.java
        )
        dataProvider = entryPoint.shortcutsDataProvider()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_COMPLETE_TASK -> {
                completeNextTask()
            }
            ACTION_DISMISS -> {
                stopSelf()
            }
            ACTION_REFRESH, ACTION_START -> {
                serviceScope.launch {
                    updateNotification()
                }
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        notificationManager.cancel(NOTIFICATION_ID)
    }

    /**
     * Create notification channel (required for API 26+)
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.notification_channel_description)
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Update the notification with current task data
     */
    private suspend fun updateNotification() {
        val summary = dataProvider.getSummary()
        val settings = dataProvider.getSettings()
        val hasTask = summary.displayList.isNotEmpty()
        val taskCount = summary.counters.outstandingTotal

        val notification = buildNotification(
            hasTask = hasTask,
            taskCount = taskCount,
            nextTaskTitle = summary.displayList.firstOrNull()?.maskedTitle,
            privacyMode = settings.privacyMode
        )

        startForeground(NOTIFICATION_ID, notification)
    }

    /**
     * Build the notification
     */
    private fun buildNotification(
        hasTask: Boolean,
        taskCount: Int,
        nextTaskTitle: String?,
        privacyMode: PrivacyMode
    ): Notification {
        // Main app intent
        val mainIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val mainPendingIntent = PendingIntent.getActivity(
            this,
            0,
            mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Complete action intent
        val completeIntent = Intent(this, LivePlanNotificationService::class.java).apply {
            action = ACTION_COMPLETE_TASK
        }
        val completePendingIntent = PendingIntent.getService(
            this,
            1,
            completeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Dismiss action intent
        val dismissIntent = Intent(this, LivePlanNotificationService::class.java).apply {
            action = ACTION_DISMISS
        }
        val dismissPendingIntent = PendingIntent.getService(
            this,
            2,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification content
        val title = getString(R.string.notification_title)
        val content = if (hasTask) {
            when (privacyMode) {
                PrivacyMode.LEVEL_0 -> {
                    nextTaskTitle ?: getString(R.string.notification_task_count, taskCount)
                }
                PrivacyMode.LEVEL_1 -> {
                    getString(R.string.notification_task_count, taskCount)
                }
                PrivacyMode.LEVEL_2 -> {
                    getString(R.string.notification_task_count, taskCount)
                }
            }
        } else {
            getString(R.string.notification_no_tasks)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(mainPendingIntent)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setVisibility(
                when (privacyMode) {
                    PrivacyMode.LEVEL_0 -> NotificationCompat.VISIBILITY_PUBLIC
                    PrivacyMode.LEVEL_1 -> NotificationCompat.VISIBILITY_PRIVATE
                    PrivacyMode.LEVEL_2 -> NotificationCompat.VISIBILITY_SECRET
                }
            )
            .apply {
                if (hasTask) {
                    addAction(
                        R.drawable.ic_check,
                        getString(R.string.notification_action_complete),
                        completePendingIntent
                    )
                }
                addAction(
                    R.drawable.ic_close,
                    getString(R.string.notification_action_dismiss),
                    dismissPendingIntent
                )
            }
            .build()
    }

    /**
     * Complete the next task and update notification
     */
    private fun completeNextTask() {
        serviceScope.launch {
            val result = dataProvider.completeNextTask()

            when (result) {
                is ShortcutResult.Success -> {
                    Toast.makeText(applicationContext, result.message, Toast.LENGTH_SHORT).show()
                    refreshWidget()
                }
                is ShortcutResult.Error -> {
                    Toast.makeText(applicationContext, result.message, Toast.LENGTH_SHORT).show()
                }
            }

            // Update notification after action
            updateNotification()
        }
    }

    /**
     * Request widget refresh after task completion
     */
    private fun refreshWidget() {
        try {
            val intent = Intent("com.liveplan.widget.REFRESH")
            intent.setPackage(packageName)
            sendBroadcast(intent)
        } catch (e: Exception) {
            // Ignore widget refresh errors
        }
    }

    companion object {
        private const val CHANNEL_ID = "liveplan_progress"
        private const val NOTIFICATION_ID = 1001

        const val ACTION_START = "com.liveplan.shortcuts.notification.START"
        const val ACTION_REFRESH = "com.liveplan.shortcuts.notification.REFRESH"
        const val ACTION_COMPLETE_TASK = "com.liveplan.shortcuts.notification.COMPLETE"
        const val ACTION_DISMISS = "com.liveplan.shortcuts.notification.DISMISS"

        /**
         * Start the notification service
         */
        fun start(context: Context) {
            val intent = Intent(context, LivePlanNotificationService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /**
         * Stop the notification service
         */
        fun stop(context: Context) {
            val intent = Intent(context, LivePlanNotificationService::class.java)
            context.stopService(intent)
        }

        /**
         * Refresh the notification content
         */
        fun refresh(context: Context) {
            val intent = Intent(context, LivePlanNotificationService::class.java).apply {
                action = ACTION_REFRESH
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
}
