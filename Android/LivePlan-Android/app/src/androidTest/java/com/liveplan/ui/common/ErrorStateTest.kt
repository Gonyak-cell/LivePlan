package com.liveplan.ui.common

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.liveplan.ui.theme.LivePlanTheme
import org.junit.Rule
import org.junit.Test

/**
 * UI tests for ErrorState composables
 */
class ErrorStateTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun errorState_displaysMessage() {
        composeTestRule.setContent {
            LivePlanTheme {
                ErrorState(message = "Something went wrong")
            }
        }

        composeTestRule.onNodeWithText("Something went wrong").assertIsDisplayed()
    }

    @Test
    fun errorState_displaysTitle() {
        composeTestRule.setContent {
            LivePlanTheme {
                ErrorState(
                    title = "Error Title",
                    message = "Error message"
                )
            }
        }

        composeTestRule.onNodeWithText("Error Title").assertIsDisplayed()
        composeTestRule.onNodeWithText("Error message").assertIsDisplayed()
    }

    @Test
    fun errorState_retryButtonWorks() {
        var retryClicked = false

        composeTestRule.setContent {
            LivePlanTheme {
                ErrorState(
                    message = "Error",
                    onRetry = { retryClicked = true }
                )
            }
        }

        composeTestRule.onNodeWithText("Retry").performClick()
        assert(retryClicked) { "Retry callback should have been triggered" }
    }

    @Test
    fun genericErrorState_displaysCorrectContent() {
        composeTestRule.setContent {
            LivePlanTheme {
                GenericErrorState(onRetry = {})
            }
        }

        composeTestRule.onNodeWithText("Something Went Wrong").assertIsDisplayed()
        composeTestRule.onNodeWithText("Retry").assertIsDisplayed()
    }

    @Test
    fun notFoundState_displaysCorrectContent() {
        composeTestRule.setContent {
            LivePlanTheme {
                NotFoundState(
                    itemType = "Project",
                    onNavigateBack = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Project Not Found").assertIsDisplayed()
        composeTestRule.onNodeWithText("Go Back").assertIsDisplayed()
    }

    @Test
    fun notFoundState_navigateBackWorks() {
        var navigatedBack = false

        composeTestRule.setContent {
            LivePlanTheme {
                NotFoundState(
                    itemType = "Task",
                    onNavigateBack = { navigatedBack = true }
                )
            }
        }

        composeTestRule.onNodeWithText("Go Back").performClick()
        assert(navigatedBack) { "Navigate back callback should have been triggered" }
    }
}
