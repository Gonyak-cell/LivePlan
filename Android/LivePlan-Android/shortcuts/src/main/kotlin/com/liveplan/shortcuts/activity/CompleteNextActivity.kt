package com.liveplan.shortcuts.activity

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
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
 * Complete Next Task Activity for App Shortcuts
 *
 * This transparent activity immediately completes the next task
 * and shows a toast with the result. It's triggered from the app
 * shortcut on long-press of the app icon.
 *
 * Behavior:
 * - Completes displayList[0] task immediately
 * - Shows toast with result
 * - Finishes immediately after action
 * - Respects privacy mode for toast message
 */
class CompleteNextActivity : ComponentActivity() {

    private val activityScope = CoroutineScope(Dispatchers.Main + Job())
    private lateinit var dataProvider: ShortcutsDataProvider

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize data provider via Hilt entry point
        val entryPoint = EntryPointAccessors.fromApplication(
            applicationContext,
            ShortcutsEntryPoint::class.java
        )
        dataProvider = entryPoint.shortcutsDataProvider()

        completeNextTask()
    }

    override fun onDestroy() {
        super.onDestroy()
        activityScope.cancel()
    }

    private fun completeNextTask() {
        activityScope.launch {
            val result = dataProvider.completeNextTask()

            when (result) {
                is ShortcutResult.Success -> {
                    Toast.makeText(this@CompleteNextActivity, result.message, Toast.LENGTH_SHORT).show()
                    refreshWidget()
                }
                is ShortcutResult.Error -> {
                    Toast.makeText(this@CompleteNextActivity, result.message, Toast.LENGTH_SHORT).show()
                }
            }

            finish()
        }
    }

    private fun refreshWidget() {
        try {
            val intent = android.content.Intent("com.liveplan.widget.REFRESH")
            intent.setPackage(packageName)
            sendBroadcast(intent)
        } catch (e: Exception) {
            // Ignore widget refresh errors
        }
    }
}
