package com.liveplan.widget.ui

import android.content.ComponentName
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.liveplan.core.model.PrivacyMode
import com.liveplan.core.selection.LockScreenSummary
import com.liveplan.widget.R
import com.liveplan.widget.data.WidgetDataProvider
import com.liveplan.widget.data.WidgetState
import dagger.hilt.android.EntryPointAccessors

/**
 * Medium Widget (4x2)
 * Displays Top 3 tasks + counter (outstanding/overdue)
 *
 * Aligned with iOS Lock Screen Widget (Rectangular)
 */
class MediumWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        // Get data provider through Hilt entry point
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            WidgetEntryPoint::class.java
        )
        val dataProvider = entryPoint.widgetDataProvider()

        // Fetch widget state
        val state = dataProvider.getWidgetState()

        provideContent {
            GlanceTheme {
                MediumWidgetContent(
                    context = context,
                    state = state
                )
            }
        }
    }
}

@Composable
private fun MediumWidgetContent(
    context: Context,
    state: WidgetState
) {
    val mainActivityComponent = ComponentName(
        context.packageName,
        "${context.packageName}.MainActivity"
    )

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .cornerRadius(WidgetTheme.cornerRadius)
            .background(WidgetTheme.Colors.background)
            .clickable(actionStartActivity(mainActivityComponent))
            .padding(WidgetTheme.paddingMedium)
    ) {
        when (state) {
            is WidgetState.Loading -> LoadingContent(context)
            is WidgetState.Error -> ErrorContent(context)
            is WidgetState.Success -> {
                if (state.isEmpty) {
                    EmptyContent(context)
                } else {
                    TaskListContent(context, state.summary)
                }
            }
        }
    }
}

@Composable
private fun LoadingContent(context: Context) {
    Box(
        modifier = GlanceModifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = context.getString(R.string.widget_loading),
            style = TextStyle(
                color = WidgetTheme.Colors.textSecondary,
                fontSize = WidgetTheme.fontSizeBody
            )
        )
    }
}

@Composable
private fun ErrorContent(context: Context) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = context.getString(R.string.widget_error_load),
            style = TextStyle(
                color = WidgetTheme.Colors.textSecondary,
                fontSize = WidgetTheme.fontSizeBody
            )
        )
        Spacer(modifier = GlanceModifier.height(4.dp))
        Text(
            text = context.getString(R.string.widget_error_tap_to_open),
            style = TextStyle(
                color = WidgetTheme.Colors.textMuted,
                fontSize = WidgetTheme.fontSizeCounter
            )
        )
    }
}

@Composable
private fun EmptyContent(context: Context) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = context.getString(R.string.widget_empty_title),
            style = TextStyle(
                color = WidgetTheme.Colors.textPrimary,
                fontSize = WidgetTheme.fontSizeBody,
                fontWeight = FontWeight.Medium
            )
        )
        Spacer(modifier = GlanceModifier.height(4.dp))
        Text(
            text = context.getString(R.string.widget_empty_message),
            style = TextStyle(
                color = WidgetTheme.Colors.textSecondary,
                fontSize = WidgetTheme.fontSizeCounter
            )
        )
    }
}

@Composable
private fun TaskListContent(
    context: Context,
    summary: LockScreenSummary
) {
    Column(
        modifier = GlanceModifier.fillMaxSize()
    ) {
        // Task list (Top 3)
        summary.displayList.take(3).forEachIndexed { index, displayTask ->
            TaskRow(context, displayTask, index)
            if (index < summary.displayList.size - 1 && index < 2) {
                Spacer(modifier = GlanceModifier.height(6.dp))
            }
        }

        Spacer(modifier = GlanceModifier.defaultWeight())

        // Counter row
        CounterRow(context, summary.counters)
    }
}

@Composable
private fun TaskRow(
    context: Context,
    displayTask: LockScreenSummary.DisplayTask,
    index: Int
) {
    val bulletText = when (displayTask.group) {
        LockScreenSummary.PriorityGroup.G1_DOING ->
            context.getString(R.string.widget_task_bullet_doing)
        LockScreenSummary.PriorityGroup.G2_OVERDUE ->
            context.getString(R.string.widget_task_bullet_overdue)
        else ->
            context.getString(R.string.widget_task_bullet)
    }

    val bulletColor = when (displayTask.group) {
        LockScreenSummary.PriorityGroup.G1_DOING -> WidgetTheme.Colors.doing
        LockScreenSummary.PriorityGroup.G2_OVERDUE -> WidgetTheme.Colors.overdue
        LockScreenSummary.PriorityGroup.G3_DUE_SOON -> WidgetTheme.Colors.dueSoon
        LockScreenSummary.PriorityGroup.G4_P1 -> WidgetTheme.Colors.p1
        else -> WidgetTheme.Colors.textPrimary
    }

    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = bulletText,
            style = TextStyle(
                color = bulletColor,
                fontSize = WidgetTheme.fontSizeBody
            )
        )
        Spacer(modifier = GlanceModifier.width(8.dp))
        Text(
            text = displayTask.maskedTitle,
            style = TextStyle(
                color = WidgetTheme.Colors.textPrimary,
                fontSize = WidgetTheme.fontSizeBody
            ),
            maxLines = 1
        )
    }
}

@Composable
private fun CounterRow(
    context: Context,
    counters: LockScreenSummary.Counters
) {
    val counterText = if (counters.dueSoonCount > 0) {
        context.getString(
            R.string.widget_counter_with_duesoon_format,
            counters.outstandingTotal,
            counters.overdueCount,
            counters.dueSoonCount
        )
    } else {
        context.getString(
            R.string.widget_counter_format,
            counters.outstandingTotal,
            counters.overdueCount
        )
    }

    Text(
        text = counterText,
        style = TextStyle(
            color = WidgetTheme.Colors.textSecondary,
            fontSize = WidgetTheme.fontSizeCounter
        )
    )
}

/**
 * Medium Widget Receiver
 */
class MediumWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MediumWidget()
}
