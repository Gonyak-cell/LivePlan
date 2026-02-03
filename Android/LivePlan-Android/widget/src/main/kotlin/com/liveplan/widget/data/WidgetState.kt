package com.liveplan.widget.data

import com.liveplan.core.selection.LockScreenSummary

/**
 * Widget display state
 * Represents the data to be displayed in the widget
 */
sealed class WidgetState {
    /**
     * Loading state
     */
    data object Loading : WidgetState()

    /**
     * Success state with lock screen summary
     */
    data class Success(
        val summary: LockScreenSummary
    ) : WidgetState() {
        val hasData: Boolean
            get() = summary.displayList.isNotEmpty()

        val isEmpty: Boolean
            get() = summary.displayList.isEmpty() && summary.counters.outstandingTotal == 0
    }

    /**
     * Error state
     */
    data class Error(
        val message: String? = null
    ) : WidgetState()

    companion object {
        /**
         * Empty success state
         */
        val EMPTY = Success(LockScreenSummary.EMPTY)
    }
}
