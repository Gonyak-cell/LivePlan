package com.liveplan.shortcuts.activity

import android.os.Bundle
import android.view.WindowManager
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.liveplan.shortcuts.R
import com.liveplan.shortcuts.data.ShortcutResult
import com.liveplan.shortcuts.data.ShortcutsDataProvider
import com.liveplan.shortcuts.di.ShortcutsEntryPoint
import dagger.hilt.android.EntryPointAccessors
import kotlinx.coroutines.launch

/**
 * Quick Add Activity for App Shortcuts
 *
 * This transparent activity displays a floating dialog for quick task entry.
 * It's triggered from the app shortcut on long-press of the app icon.
 *
 * Features:
 * - Minimal UI for fast task entry
 * - Auto-focus on text field
 * - Submit on IME action
 * - Auto-dismiss after adding
 */
class QuickAddActivity : ComponentActivity() {

    private lateinit var dataProvider: ShortcutsDataProvider

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make activity transparent
        window.setFlags(
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        )

        // Initialize data provider via Hilt entry point
        val entryPoint = EntryPointAccessors.fromApplication(
            applicationContext,
            ShortcutsEntryPoint::class.java
        )
        dataProvider = entryPoint.shortcutsDataProvider()

        setContent {
            MaterialTheme {
                QuickAddDialog(
                    onDismiss = { finish() },
                    onAdd = { title -> addTask(title) }
                )
            }
        }
    }

    private fun addTask(title: String) {
        kotlinx.coroutines.GlobalScope.launch {
            val result = dataProvider.quickAddTask(title)

            runOnUiThread {
                when (result) {
                    is ShortcutResult.Success -> {
                        Toast.makeText(this@QuickAddActivity, result.message, Toast.LENGTH_SHORT).show()
                        refreshWidget()
                        finish()
                    }
                    is ShortcutResult.Error -> {
                        Toast.makeText(this@QuickAddActivity, result.message, Toast.LENGTH_SHORT).show()
                    }
                }
            }
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

@Composable
private fun QuickAddDialog(
    onDismiss: () -> Unit,
    onAdd: (String) -> Unit
) {
    var taskTitle by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    val focusRequester = remember { FocusRequester() }
    val scope = rememberCoroutineScope()

    // Auto-focus on text field
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        )
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth(0.9f)
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier.padding(20.dp)
            ) {
                Text(
                    text = stringResource(R.string.quick_add_title),
                    style = MaterialTheme.typography.titleLarge
                )

                Spacer(modifier = Modifier.height(16.dp))

                OutlinedTextField(
                    value = taskTitle,
                    onValueChange = { taskTitle = it },
                    modifier = Modifier
                        .fillMaxWidth()
                        .focusRequester(focusRequester),
                    placeholder = {
                        Text(stringResource(R.string.quick_add_hint))
                    },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = {
                            if (taskTitle.isNotBlank() && !isLoading) {
                                isLoading = true
                                onAdd(taskTitle)
                            }
                        }
                    ),
                    enabled = !isLoading
                )

                Spacer(modifier = Modifier.height(20.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    TextButton(
                        onClick = onDismiss,
                        enabled = !isLoading
                    ) {
                        Text(stringResource(android.R.string.cancel))
                    }

                    Spacer(modifier = Modifier.width(8.dp))

                    Button(
                        onClick = {
                            if (taskTitle.isNotBlank()) {
                                isLoading = true
                                onAdd(taskTitle)
                            }
                        },
                        enabled = taskTitle.isNotBlank() && !isLoading
                    ) {
                        Text(stringResource(R.string.quick_add_button))
                    }
                }
            }
        }
    }
}
