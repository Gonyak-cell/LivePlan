package com.liveplan.navigation

/**
 * Navigation routes for LivePlan
 * Aligned with iOS navigation structure
 */
sealed class Screen(val route: String) {

    /**
     * Project list screen (home)
     */
    data object Projects : Screen("projects")

    /**
     * Project detail screen
     * @param projectId Project ID parameter
     */
    data object ProjectDetail : Screen("project/{projectId}") {
        fun createRoute(projectId: String) = "project/$projectId"
        const val ARG_PROJECT_ID = "projectId"
    }

    /**
     * Task create screen
     * @param projectId Parent project ID
     */
    data object TaskCreate : Screen("task/create/{projectId}") {
        fun createRoute(projectId: String) = "task/create/$projectId"
        const val ARG_PROJECT_ID = "projectId"
    }

    /**
     * Task detail screen
     * @param taskId Task ID parameter
     */
    data object TaskDetail : Screen("task/{taskId}") {
        fun createRoute(taskId: String) = "task/$taskId"
        const val ARG_TASK_ID = "taskId"
    }

    /**
     * Settings screen
     */
    data object Settings : Screen("settings")

    /**
     * Search screen
     */
    data object Search : Screen("search")

    /**
     * Filter list screen
     */
    data object Filters : Screen("filters")

    /**
     * Filter builder screen (create)
     */
    data object FilterCreate : Screen("filter/create")

    /**
     * Filter builder screen (edit)
     * @param filterId Filter ID parameter
     */
    data object FilterEdit : Screen("filter/{filterId}") {
        fun createRoute(filterId: String) = "filter/$filterId"
        const val ARG_FILTER_ID = "filterId"
    }

    /**
     * Filter results screen
     * @param filterId Filter ID parameter
     */
    data object FilterResults : Screen("filter/{filterId}/results") {
        fun createRoute(filterId: String) = "filter/$filterId/results"
        const val ARG_FILTER_ID = "filterId"
    }
}
