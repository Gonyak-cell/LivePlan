package com.liveplan.ui.common

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Folder
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.liveplan.ui.theme.LivePlanTheme
import org.junit.Rule
import org.junit.Test

/**
 * UI tests for EmptyState composables
 */
class EmptyStateTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun emptyState_displaysTitle() {
        composeTestRule.setContent {
            LivePlanTheme {
                EmptyState(
                    icon = Icons.Default.Folder,
                    title = "Test Title",
                    description = "Test Description"
                )
            }
        }

        composeTestRule.onNodeWithText("Test Title").assertIsDisplayed()
    }

    @Test
    fun emptyState_displaysDescription() {
        composeTestRule.setContent {
            LivePlanTheme {
                EmptyState(
                    icon = Icons.Default.Folder,
                    title = "Test Title",
                    description = "Test Description"
                )
            }
        }

        composeTestRule.onNodeWithText("Test Description").assertIsDisplayed()
    }

    @Test
    fun emptyState_displaysActionButton() {
        var clicked = false

        composeTestRule.setContent {
            LivePlanTheme {
                EmptyState(
                    icon = Icons.Default.Folder,
                    title = "Test Title",
                    description = "Test Description",
                    actionLabel = "Action Button",
                    onAction = { clicked = true }
                )
            }
        }

        composeTestRule.onNodeWithText("Action Button").assertIsDisplayed()
        composeTestRule.onNodeWithText("Action Button").performClick()

        assert(clicked) { "Action callback should have been triggered" }
    }

    @Test
    fun emptyState_hidesActionButtonWhenNotProvided() {
        composeTestRule.setContent {
            LivePlanTheme {
                EmptyState(
                    icon = Icons.Default.Folder,
                    title = "Test Title",
                    description = "Test Description"
                )
            }
        }

        composeTestRule.onNodeWithText("Action Button").assertDoesNotExist()
    }

    @Test
    fun emptyProjectsState_displaysCorrectContent() {
        composeTestRule.setContent {
            LivePlanTheme {
                EmptyProjectsState(onCreateProject = {})
            }
        }

        composeTestRule.onNodeWithText("No Projects Yet").assertIsDisplayed()
        composeTestRule.onNodeWithText("Create Project").assertIsDisplayed()
    }

    @Test
    fun emptyTasksState_displaysCorrectContent() {
        composeTestRule.setContent {
            LivePlanTheme {
                EmptyTasksState(onCreateTask = {})
            }
        }

        composeTestRule.onNodeWithText("No Tasks Yet").assertIsDisplayed()
        composeTestRule.onNodeWithText("Add Task").assertIsDisplayed()
    }

    @Test
    fun allTasksCompletedState_displaysCorrectContent() {
        composeTestRule.setContent {
            LivePlanTheme {
                AllTasksCompletedState()
            }
        }

        composeTestRule.onNodeWithText("All Done!").assertIsDisplayed()
    }
}
