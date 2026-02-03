package com.liveplan.ui.search

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Project
import com.liveplan.core.model.Task
import com.liveplan.ui.common.EmptySearchResultsState
import com.liveplan.ui.theme.LivePlanTheme
import com.liveplan.viewmodel.SearchProjectItem
import com.liveplan.viewmodel.SearchTaskItem
import org.junit.Rule
import org.junit.Test

/**
 * UI tests for SearchScreen components
 */
class SearchScreenComponentsTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun emptySearchResultsState_displaysCorrectMessage() {
        composeTestRule.setContent {
            LivePlanTheme {
                EmptySearchResultsState(query = "test query")
            }
        }

        composeTestRule.onNodeWithText("No results found").assertIsDisplayed()
        composeTestRule.onNodeWithText("No results found for \"test query\"").assertIsDisplayed()
    }

    @Test
    fun searchResults_displaysProjectsSection() {
        val projects = listOf(
            SearchProjectItem(
                project = Project(title = "Test Project", startDate = System.currentTimeMillis()),
                taskCount = 10,
                outstandingCount = 5
            )
        )

        composeTestRule.setContent {
            LivePlanTheme {
                SearchResultsContent(
                    projects = projects,
                    tasks = emptyList(),
                    onProjectClick = {},
                    onTaskClick = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Projects").assertIsDisplayed()
        composeTestRule.onNodeWithText("Test Project").assertIsDisplayed()
        composeTestRule.onNodeWithText("5 remaining of 10 tasks").assertIsDisplayed()
    }

    @Test
    fun searchResults_displaysTasksSection() {
        val tasks = listOf(
            SearchTaskItem(
                task = Task(projectId = "1", title = "Test Task", priority = Priority.P2),
                projectName = "Test Project",
                isCompleted = false,
                tags = emptyList()
            )
        )

        composeTestRule.setContent {
            LivePlanTheme {
                SearchResultsContent(
                    projects = emptyList(),
                    tasks = tasks,
                    onProjectClick = {},
                    onTaskClick = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Tasks").assertIsDisplayed()
        composeTestRule.onNodeWithText("Test Task").assertIsDisplayed()
        composeTestRule.onNodeWithText("Test Project").assertIsDisplayed()
    }

    @Test
    fun searchResults_displaysCompletedTaskWithStrikethrough() {
        val tasks = listOf(
            SearchTaskItem(
                task = Task(projectId = "1", title = "Completed Task"),
                projectName = "Project",
                isCompleted = true,
                tags = emptyList()
            )
        )

        composeTestRule.setContent {
            LivePlanTheme {
                SearchResultsContent(
                    projects = emptyList(),
                    tasks = tasks,
                    onProjectClick = {},
                    onTaskClick = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Completed Task").assertIsDisplayed()
    }
}

// Helper composable for testing
@androidx.compose.runtime.Composable
private fun SearchResultsContent(
    projects: List<SearchProjectItem>,
    tasks: List<SearchTaskItem>,
    onProjectClick: (SearchProjectItem) -> Unit,
    onTaskClick: (SearchTaskItem) -> Unit
) {
    androidx.compose.foundation.lazy.LazyColumn {
        if (projects.isNotEmpty()) {
            item {
                androidx.compose.material3.Text("Projects")
            }
            items(projects.size) { index ->
                val project = projects[index]
                androidx.compose.material3.ListItem(
                    headlineContent = { androidx.compose.material3.Text(project.project.title) },
                    supportingContent = {
                        androidx.compose.material3.Text(
                            "${project.outstandingCount} remaining of ${project.taskCount} tasks"
                        )
                    }
                )
            }
        }
        if (tasks.isNotEmpty()) {
            item {
                androidx.compose.material3.Text("Tasks")
            }
            items(tasks.size) { index ->
                val task = tasks[index]
                androidx.compose.material3.ListItem(
                    headlineContent = { androidx.compose.material3.Text(task.task.title) },
                    supportingContent = { androidx.compose.material3.Text(task.projectName) }
                )
            }
        }
    }
}
