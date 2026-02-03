package com.liveplan.shortcuts.tiles

import android.content.ComponentName
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.widget.Toast
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
 * Quick Settings Tile for completing the next task
 *
 * This tile appears in the Quick Settings panel and allows users
 * to complete their next outstanding task with a single tap.
 *
 * Behavior:
 * - Shows current task count in subtitle (API 29+)
 * - Tapping completes displayList[0] task
 * - Shows toast with completion result
 * - Updates tile state after action
 */
class CompleteTaskTileService : TileService() {

    private val serviceScope = CoroutineScope(Dispatchers.Main + Job())
    private lateinit var dataProvider: ShortcutsDataProvider

    override fun onCreate() {
        super.onCreate()
        val entryPoint = EntryPointAccessors.fromApplication(
            applicationContext,
            ShortcutsEntryPoint::class.java
        )
        dataProvider = entryPoint.shortcutsDataProvider()
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
    }

    /**
     * Called when the tile is added to Quick Settings
     */
    override fun onTileAdded() {
        super.onTileAdded()
        updateTileState()
    }

    /**
     * Called when the tile becomes visible
     */
    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }

    /**
     * Called when the tile is clicked
     */
    override fun onClick() {
        super.onClick()
        completeNextTask()
    }

    /**
     * Update the tile state based on current data
     */
    private fun updateTileState() {
        serviceScope.launch {
            try {
                val summary = dataProvider.getSummary()
                val hasTask = summary.displayList.isNotEmpty()
                val taskCount = summary.counters.outstandingTotal

                qsTile?.apply {
                    state = if (hasTask) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE

                    label = getString(R.string.tile_complete_task_label)

                    // Subtitle available on API 29+
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        subtitle = if (hasTask) {
                            getString(R.string.notification_task_count, taskCount)
                        } else {
                            getString(R.string.tile_no_task)
                        }
                    }

                    // Content description for accessibility
                    contentDescription = if (hasTask) {
                        getString(R.string.tile_complete_task_subtitle)
                    } else {
                        getString(R.string.tile_no_task)
                    }

                    updateTile()
                }
            } catch (e: Exception) {
                // Fail-safe: show inactive state on error
                qsTile?.apply {
                    state = Tile.STATE_INACTIVE
                    label = getString(R.string.tile_complete_task_label)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        subtitle = getString(R.string.tile_no_task)
                    }
                    updateTile()
                }
            }
        }
    }

    /**
     * Complete the next task
     */
    private fun completeNextTask() {
        serviceScope.launch {
            // Check if unlocked (API 24+)
            if (!isLocked) {
                executeCompleteTask()
            } else {
                // Unlock device first, then execute
                unlockAndRun { executeCompleteTask() }
            }
        }
    }

    private fun executeCompleteTask() {
        serviceScope.launch {
            val result = dataProvider.completeNextTask()

            when (result) {
                is ShortcutResult.Success -> {
                    showToast(result.message)
                    // Refresh widget after completion
                    refreshWidget()
                }
                is ShortcutResult.Error -> {
                    showToast(result.message)
                }
            }

            // Update tile state after action
            updateTileState()
        }
    }

    private fun showToast(message: String) {
        Toast.makeText(applicationContext, message, Toast.LENGTH_SHORT).show()
    }

    /**
     * Request widget refresh after task completion
     */
    private fun refreshWidget() {
        try {
            val intent = android.content.Intent("com.liveplan.widget.REFRESH")
            intent.setPackage(packageName)
            sendBroadcast(intent)
        } catch (e: Exception) {
            // Ignore widget refresh errors
        }
    }

    companion object {
        /**
         * Request the system to refresh this tile
         */
        fun requestTileStateUpdate(context: Context) {
            requestListeningState(
                context,
                ComponentName(context, CompleteTaskTileService::class.java)
            )
        }
    }
}
