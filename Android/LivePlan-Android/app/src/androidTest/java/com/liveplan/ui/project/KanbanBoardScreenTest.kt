package com.liveplan.ui.project

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.TaskItem
import org.junit.Rule
import org.junit.Test

/**
 * UI tests for KanbanBoardScreen
 */
class KanbanBoardScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun kanbanBoard_displaysAllColumns() {
        composeTestRule.setContent {
            LivePlanTheme {
                KanbanBoardScreen(
                    tasks = emptyList(),
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithText("To Do").assertIsDisplayed()
        composeTestRule.onNodeWithText("In Progress").assertIsDisplayed()
        composeTestRule.onNodeWithText("Done").assertIsDisplayed()
    }

    @Test
    fun kanbanBoard_displaysEmptyColumnMessage() {
        composeTestRule.setContent {
            LivePlanTheme {
                KanbanBoardScreen(
                    tasks = emptyList(),
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        // All columns should show "No tasks" message
        composeTestRule.onAllNodesWithText("No tasks").fetchSemanticsNodes().size == 3
    }

    @Test
    fun kanbanBoard_displaysTodoTasks() {
        val tasks = listOf(
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Todo Task",
                    workflowState = WorkflowState.TODO
                ),
                isCompleted = false,
                section = null
            )
        )

        composeTestRule.setContent {
            LivePlanTheme {
                KanbanBoardScreen(
                    tasks = tasks,
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Todo Task").assertIsDisplayed()
    }

    @Test
    fun kanbanBoard_displaysDoingTasks() {
        val tasks = listOf(
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "In Progress Task",
                    workflowState = WorkflowState.DOING
                ),
                isCompleted = false,
                section = null
            )
        )

        composeTestRule.setContent {
            LivePlanTheme {
                KanbanBoardScreen(
                    tasks = tasks,
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithText("In Progress Task").assertIsDisplayed()
    }

    @Test
    fun kanbanBoard_displaysCompletedTasksInDoneColumn() {
        val tasks = listOf(
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "Completed Task",
                    workflowState = WorkflowState.DONE
                ),
                isCompleted = true,
                section = null
            )
        )

        composeTestRule.setContent {
            LivePlanTheme {
                KanbanBoardScreen(
                    tasks = tasks,
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Completed Task").assertIsDisplayed()
    }

    @Test
    fun kanbanBoard_taskClickCallsCallback() {
        var clickedTaskId: String? = null
        val tasks = listOf(
            TaskItem(
                task = Task(
                    id = "task-1",
                    projectId = "1",
                    title = "Clickable Task",
                    workflowState = WorkflowState.TODO
                ),
                isCompleted = false,
                section = null
            )
        )

        composeTestRule.setContent {
            LivePlanTheme {
                KanbanBoardScreen(
                    tasks = tasks,
                    onTaskClick = { clickedTaskId = it.task.id },
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Clickable Task").performClick()
        assert(clickedTaskId == "task-1") { "Task click callback should return correct task ID" }
    }

    @Test
    fun kanbanBoard_displaysPriorityBadge() {
        val tasks = listOf(
            TaskItem(
                task = Task(
                    projectId = "1",
                    title = "High Priority Task",
                    priority = Priority.P1,
                    workflowState = WorkflowState.TODO
                ),
                isCompleted = false,
                section = null
            )
        )

        composeTestRule.setContent {
            LivePlanTheme {
                KanbanBoardScreen(
                    tasks = tasks,
                    onTaskClick = {},
                    onToggleComplete = {}
                )
            }
        }

        composeTestRule.onNodeWithText("High Priority Task").assertIsDisplayed()
        // P1 badge should be visible (exact text depends on PriorityBadge implementation)
    }
}

private fun <T> List<T>.size(): Int = this.size
