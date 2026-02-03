package com.liveplan.widget.ui

import android.content.ComponentName
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
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
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.liveplan.core.selection.LockScreenSummary
import com.liveplan.widget.R
import com.liveplan.widget.data.WidgetState
import dagger.hilt.android.EntryPointAccessors

/**
 * Small Widget (2x2)
 * Displays count-focused summary
 *
 * Aligned with iOS Lock Screen Widget (Small/Circular)
 */
class SmallWidget : GlanceAppWidget() {

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
                SmallWidgetContent(
                    context = context,
                    state = state
                )
            }
        }
    }
}

@Composable
private fun SmallWidgetContent(
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
            .padding(WidgetTheme.paddingMedium),
        contentAlignment = Alignment.Center
    ) {
        when (state) {
            is WidgetState.Loading -> LoadingContent(context)
            is WidgetState.Error -> ErrorContent(context)
            is WidgetState.Success -> CountContent(context, state.summary)
        }
    }
}

@Composable
private fun LoadingContent(context: Context) {
    Text(
        text = context.getString(R.string.widget_loading),
        style = TextStyle(
            color = WidgetTheme.Colors.textSecondary,
            fontSize = WidgetTheme.fontSizeBody
        )
    )
}

@Composable
private fun ErrorContent(context: Context) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "!",
            style = TextStyle(
                color = WidgetTheme.Colors.overdue,
                fontSize = WidgetTheme.fontSizeLarge,
                fontWeight = FontWeight.Bold
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
private fun CountContent(
    context: Context,
    summary: LockScreenSummary
) {
    val counters = summary.counters
    val hasOverdue = counters.overdueCount > 0
    val hasDueSoon = counters.dueSoonCount > 0

    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Main count
        val countColor = when {
            hasOverdue -> WidgetTheme.Colors.overdue
            hasDueSoon -> WidgetTheme.Colors.dueSoon
            else -> WidgetTheme.Colors.textPrimary
        }

        Text(
            text = counters.outstandingTotal.toString(),
            style = TextStyle(
                color = countColor,
                fontSize = WidgetTheme.fontSizeLarge,
                fontWeight = FontWeight.Bold
            )
        )

        Spacer(modifier = GlanceModifier.height(4.dp))

        // Label
        Text(
            text = context.getString(R.string.widget_outstanding_label),
            style = TextStyle(
                color = WidgetTheme.Colors.textSecondary,
                fontSize = WidgetTheme.fontSizeCounter
            )
        )

        // Overdue indicator (if any)
        if (hasOverdue) {
            Spacer(modifier = GlanceModifier.height(4.dp))
            Text(
                text = "${context.getString(R.string.widget_overdue_label)} ${counters.overdueCount}",
                style = TextStyle(
                    color = WidgetTheme.Colors.overdue,
                    fontSize = WidgetTheme.fontSizeCounter
                )
            )
        }
    }
}

/**
 * Small Widget Receiver
 */
class SmallWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = SmallWidget()
}
