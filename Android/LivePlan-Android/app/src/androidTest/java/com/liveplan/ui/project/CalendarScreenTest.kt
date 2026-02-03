package com.liveplan.ui.project

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Task
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.TaskItem
import org.junit.Rule
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * UI tests for CalendarScreen
 */
class CalendarScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun calendarScreen_displaysCurrentMonth() {
        val currentMonth = Calendar.getInstance()
        val monthFormat = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
        val expectedMonthText = monthFormat.format(currentMonth.time)

        composeTestRule.setContent {
            LivePlanTheme {
                CalendarScreen(
                    tasks = emptyList(),
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithText(expectedMonthText).assertIsDisplayed()
    }

    @Test
    fun calendarScreen_displaysNavigationButtons() {
        composeTestRule.setContent {
            LivePlanTheme {
                CalendarScreen(
                    tasks = emptyList(),
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithContentDescription("Previous month").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Next month").assertIsDisplayed()
    }

    @Test
    fun calendarScreen_navigatesToPreviousMonth() {
        val currentMonth = Calendar.getInstance()
        val previousMonth = (currentMonth.clone() as Calendar).apply {
            add(Calendar.MONTH, -1)
        }
        val monthFormat = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
        val expectedMonthText = monthFormat.format(previousMonth.time)

        composeTestRule.setContent {
            LivePlanTheme {
                CalendarScreen(
                    tasks = emptyList(),
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithContentDescription("Previous month").performClick()
        composeTestRule.onNodeWithText(expectedMonthText).assertIsDisplayed()
    }

    @Test
    fun calendarScreen_navigatesToNextMonth() {
        val currentMonth = Calendar.getInstance()
        val nextMonth = (currentMonth.clone() as Calendar).apply {
            add(Calendar.MONTH, 1)
        }
        val monthFormat = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
        val expectedMonthText = monthFormat.format(nextMonth.time)

        composeTestRule.setContent {
            LivePlanTheme {
                CalendarScreen(
                    tasks = emptyList(),
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithContentDescription("Next month").performClick()
        composeTestRule.onNodeWithText(expectedMonthText).assertIsDisplayed()
    }

    @Test
    fun calendarScreen_displaysDayOfWeekHeaders() {
        composeTestRule.setContent {
            LivePlanTheme {
                CalendarScreen(
                    tasks = emptyList(),
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Sun").assertIsDisplayed()
        composeTestRule.onNodeWithText("Mon").assertIsDisplayed()
        composeTestRule.onNodeWithText("Tue").assertIsDisplayed()
        composeTestRule.onNodeWithText("Wed").assertIsDisplayed()
        composeTestRule.onNodeWithText("Thu").assertIsDisplayed()
        composeTestRule.onNodeWithText("Fri").assertIsDisplayed()
        composeTestRule.onNodeWithText("Sat").assertIsDisplayed()
    }

    @Test
    fun calendarScreen_showsNoTasksMessageWhenNoDateSelected() {
        composeTestRule.setContent {
            LivePlanTheme {
                CalendarScreen(
                    tasks = emptyList(),
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Select a date to see tasks").assertIsDisplayed()
    }

    @Test
    fun calendarScreen_displaysTasksWithDueDate() {
        val today = Calendar.getInstance()
        val tasks = listOf(
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Task Due Today",
                    priority = Priority.P1,
                    dueAt = today.timeInMillis
                ),
                isCompleted = false,
                section = null
            )
        )

        composeTestRule.setContent {
            LivePlanTheme {
                CalendarScreen(
                    tasks = tasks,
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        // Click on today's date to see tasks
        val dayOfMonth = today.get(Calendar.DAY_OF_MONTH).toString()
        composeTestRule.onNodeWithText(dayOfMonth).performClick()

        // Verify task is displayed
        composeTestRule.onNodeWithText("Task Due Today").assertIsDisplayed()
    }
}
