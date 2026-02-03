package com.liveplan.widget

import com.google.common.truth.Truth.assertThat
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Task
import com.liveplan.core.selection.LockScreenSummary
import com.liveplan.widget.data.WidgetState
import org.junit.Test

/**
 * Tests for WidgetState
 */
class WidgetStateTest {

    @Test
    fun `Loading state is singleton`() {
        val loading1 = WidgetState.Loading
        val loading2 = WidgetState.Loading

        assertThat(loading1).isSameInstanceAs(loading2)
    }

    @Test
    fun `Success state with empty summary returns isEmpty true`() {
        val state = WidgetState.Success(LockScreenSummary.EMPTY)

        assertThat(state.isEmpty).isTrue()
        assertThat(state.hasData).isFalse()
    }

    @Test
    fun `Success state with tasks returns hasData true`() {
        val task = Task(
            projectId = "project-1",
            title = "Test Task",
            priority = Priority.P2
        )
        val displayTask = LockScreenSummary.DisplayTask(
            task = task,
            maskedTitle = "Test Task",
            group = LockScreenSummary.PriorityGroup.G6_OTHER
        )
        val summary = LockScreenSummary(
            displayList = listOf(displayTask),
            counters = LockScreenSummary.Counters(outstandingTotal = 1)
        )
        val state = WidgetState.Success(summary)

        assertThat(state.hasData).isTrue()
        assertThat(state.isEmpty).isFalse()
    }

    @Test
    fun `Success state with zero outstanding but no display list is empty`() {
        val summary = LockScreenSummary(
            displayList = emptyList(),
            counters = LockScreenSummary.Counters(outstandingTotal = 0)
        )
        val state = WidgetState.Success(summary)

        assertThat(state.isEmpty).isTrue()
    }

    @Test
    fun `Success state with only counters but no display list is not empty`() {
        // This case: displayList is empty but outstandingTotal > 0
        // (e.g., all tasks are blocked)
        val summary = LockScreenSummary(
            displayList = emptyList(),
            counters = LockScreenSummary.Counters(
                outstandingTotal = 5,
                blockedCount = 5
            )
        )
        val state = WidgetState.Success(summary)

        // Has data because outstandingTotal > 0
        assertThat(state.hasData).isFalse() // displayList is empty
        assertThat(state.isEmpty).isFalse() // outstandingTotal > 0
    }

    @Test
    fun `Error state contains message`() {
        val errorMessage = "Test error"
        val state = WidgetState.Error(errorMessage)

        assertThat(state.message).isEqualTo(errorMessage)
    }

    @Test
    fun `Error state can have null message`() {
        val state = WidgetState.Error()

        assertThat(state.message).isNull()
    }

    @Test
    fun `EMPTY constant returns empty success state`() {
        val empty = WidgetState.EMPTY

        assertThat(empty).isInstanceOf(WidgetState.Success::class.java)
        assertThat((empty as WidgetState.Success).isEmpty).isTrue()
    }
}
