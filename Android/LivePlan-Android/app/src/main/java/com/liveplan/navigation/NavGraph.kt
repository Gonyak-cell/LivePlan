package com.liveplan.navigation

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.liveplan.ui.filter.FilterBuilderScreen
import com.liveplan.ui.filter.FilterListScreen
import com.liveplan.ui.project.ProjectDetailScreen
import com.liveplan.ui.project.ProjectListScreen
import com.liveplan.ui.search.SearchScreen
import com.liveplan.ui.settings.SettingsScreen
import com.liveplan.ui.task.TaskCreateScreen
import com.liveplan.ui.task.TaskDetailScreen

/**
 * Main navigation graph for LivePlan
 */
@Composable
fun NavGraph(
    navController: NavHostController,
    modifier: Modifier = Modifier,
    startDestination: String = Screen.Projects.route
) {
    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        // Project List (Home)
        composable(route = Screen.Projects.route) {
            ProjectListScreen(
                onNavigateToProject = { projectId ->
                    navController.navigate(Screen.ProjectDetail.createRoute(projectId))
                },
                onNavigateToSettings = {
                    navController.navigate(Screen.Settings.route)
                },
                onNavigateToSearch = {
                    navController.navigate(Screen.Search.route)
                }
            )
        }

        // Project Detail
        composable(
            route = Screen.ProjectDetail.route,
            arguments = listOf(
                navArgument(Screen.ProjectDetail.ARG_PROJECT_ID) {
                    type = NavType.StringType
                }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getString(Screen.ProjectDetail.ARG_PROJECT_ID)
                ?: return@composable

            ProjectDetailScreen(
                projectId = projectId,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onNavigateToTaskCreate = {
                    navController.navigate(Screen.TaskCreate.createRoute(projectId))
                },
                onNavigateToTaskDetail = { taskId ->
                    navController.navigate(Screen.TaskDetail.createRoute(taskId))
                }
            )
        }

        // Task Create
        composable(
            route = Screen.TaskCreate.route,
            arguments = listOf(
                navArgument(Screen.TaskCreate.ARG_PROJECT_ID) {
                    type = NavType.StringType
                }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getString(Screen.TaskCreate.ARG_PROJECT_ID)
                ?: return@composable

            TaskCreateScreen(
                projectId = projectId,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onTaskCreated = {
                    navController.popBackStack()
                }
            )
        }

        // Task Detail
        composable(
            route = Screen.TaskDetail.route,
            arguments = listOf(
                navArgument(Screen.TaskDetail.ARG_TASK_ID) {
                    type = NavType.StringType
                }
            )
        ) { backStackEntry ->
            val taskId = backStackEntry.arguments?.getString(Screen.TaskDetail.ARG_TASK_ID)
                ?: return@composable

            TaskDetailScreen(
                taskId = taskId,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onTaskDeleted = {
                    navController.popBackStack()
                }
            )
        }

        // Settings
        composable(route = Screen.Settings.route) {
            SettingsScreen(
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        // Search
        composable(route = Screen.Search.route) {
            SearchScreen(
                onNavigateBack = {
                    navController.popBackStack()
                },
                onNavigateToTask = { taskId ->
                    navController.navigate(Screen.TaskDetail.createRoute(taskId))
                },
                onNavigateToProject = { projectId ->
                    navController.navigate(Screen.ProjectDetail.createRoute(projectId))
                }
            )
        }

        // Filters
        composable(route = Screen.Filters.route) {
            FilterListScreen(
                onNavigateBack = {
                    navController.popBackStack()
                },
                onNavigateToFilter = { filterId ->
                    navController.navigate(Screen.FilterResults.createRoute(filterId))
                },
                onNavigateToCreateFilter = {
                    navController.navigate(Screen.FilterCreate.route)
                }
            )
        }

        // Filter Create
        composable(route = Screen.FilterCreate.route) {
            FilterBuilderScreen(
                filterId = null,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onFilterSaved = {
                    navController.popBackStack()
                }
            )
        }

        // Filter Edit
        composable(
            route = Screen.FilterEdit.route,
            arguments = listOf(
                navArgument(Screen.FilterEdit.ARG_FILTER_ID) {
                    type = NavType.StringType
                }
            )
        ) { backStackEntry ->
            val filterId = backStackEntry.arguments?.getString(Screen.FilterEdit.ARG_FILTER_ID)
                ?: return@composable

            FilterBuilderScreen(
                filterId = filterId,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onFilterSaved = {
                    navController.popBackStack()
                }
            )
        }
    }
}
