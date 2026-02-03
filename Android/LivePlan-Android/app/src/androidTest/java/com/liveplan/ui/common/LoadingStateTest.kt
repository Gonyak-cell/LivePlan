package com.liveplan.ui.common

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import com.liveplan.ui.theme.LivePlanTheme
import org.junit.Rule
import org.junit.Test

/**
 * UI tests for LoadingState composables
 */
class LoadingStateTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun loadingState_displaysWithMessage() {
        composeTestRule.setContent {
            LivePlanTheme {
                LoadingState(message = "Loading data...")
            }
        }

        composeTestRule.onNodeWithText("Loading data...").assertIsDisplayed()
    }

    @Test
    fun fullScreenLoading_displaysDefaultMessage() {
        composeTestRule.setContent {
            LivePlanTheme {
                FullScreenLoading()
            }
        }

        composeTestRule.onNodeWithText("Loading…").assertIsDisplayed()
    }
}
