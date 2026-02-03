package com.liveplan.core.usecase

import com.liveplan.core.model.DueRange
import com.liveplan.core.model.FilterDefinition
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Task
import com.liveplan.core.model.ViewScope
import com.liveplan.core.repository.TaskRepository
import com.liveplan.core.util.DateKeyUtil
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * Apply filter use case
 * Aligned with iOS AppCore FilterDefinition application
 *
 * Filters tasks based on SavedView/FilterDefinition criteria
 */
class ApplyFilterUseCase @Inject constructor(
    private val taskRepository: TaskRepository
) {
    /**
     * Apply filter to all tasks and return matching tasks as Flow
     *
     * @param filter FilterDefinition to apply
     * @param scope ViewScope (global or project-specific)
     * @param dateKey Current dateKey for date-based filtering (default: today)
     * @return Flow of filtered tasks
     */
    operator fun invoke(
        filter: FilterDefinition,
        scope: ViewScope = ViewScope.Global,
        dateKey: String = DateKeyUtil.today()
    ): Flow<List<Task>> {
        val baseFlow = when (scope) {
            is ViewScope.Global -> taskRepository.getAllTasks()
            is ViewScope.Project -> taskRepository.getTasksByProject(scope.projectId)
        }

        return baseFlow.map { tasks ->
            applyFilter(tasks, filter, dateKey)
        }
    }

    /**
     * Apply filter to a list of tasks (synchronous version)
     *
     * @param tasks List of tasks to filter
     * @param filter FilterDefinition to apply
     * @param dateKey Current dateKey for date-based filtering
     * @return Filtered list of tasks
     */
    fun applyFilter(
        tasks: List<Task>,
        filter: FilterDefinition,
        dateKey: String = DateKeyUtil.today()
    ): List<Task> {
        val todayStartMillis = DateKeyUtil.toStartOfDayMillis(dateKey)
        val todayEndMillis = todayStartMillis + 24 * 60 * 60 * 1000L
        val next7DaysEndMillis = todayStartMillis + 7 * 24 * 60 * 60 * 1000L

        return tasks.filter { task ->
            matchesFilter(task, filter, todayStartMillis, todayEndMillis, next7DaysEndMillis)
        }
    }

    private fun matchesFilter(
        task: Task,
        filter: FilterDefinition,
        todayStartMillis: Long,
        todayEndMillis: Long,
        next7DaysEndMillis: Long
    ): Boolean {
        // Project filter
        if (filter.includeProjects != null && task.projectId !in filter.includeProjects) {
            return false
        }

        // Tag filter
        if (filter.includeTags != null && filter.includeTags.none { it in task.tagIds }) {
            return false
        }

        // Section filter
        if (filter.includeSections != null) {
            if (task.sectionId == null || task.sectionId !in filter.includeSections) {
                return false
            }
        }

        // Priority filter (priorityAtMost)
        if (filter.priorityAtMost != null && !isPriorityAtMost(task.priority, filter.priorityAtMost)) {
            return false
        }

        // Priority filter (priorityAtLeast)
        if (filter.priorityAtLeast != null && !isPriorityAtLeast(task.priority, filter.priorityAtLeast)) {
            return false
        }

        // Workflow state filter
        if (task.workflowState !in filter.stateIn) {
            return false
        }

        // Due range filter
        if (!matchesDueRange(task, filter.dueRange, todayStartMillis, todayEndMillis, next7DaysEndMillis)) {
            return false
        }

        // Recurring filter
        if (!filter.includeRecurring && task.isRecurring) {
            return false
        }

        // Blocked filter
        if (filter.excludeBlocked && task.isBlocked) {
            return false
        }

        return true
    }

    private fun isPriorityAtMost(priority: Priority, atMost: Priority): Boolean {
        // P1 is highest priority (lowest ordinal), P4 is lowest
        return priority.ordinal <= atMost.ordinal
    }

    private fun isPriorityAtLeast(priority: Priority, atLeast: Priority): Boolean {
        // P1 is highest priority (lowest ordinal), P4 is lowest
        return priority.ordinal >= atLeast.ordinal
    }

    private fun matchesDueRange(
        task: Task,
        dueRange: DueRange,
        todayStartMillis: Long,
        todayEndMillis: Long,
        next7DaysEndMillis: Long
    ): Boolean {
        return when (dueRange) {
            DueRange.NONE -> true

            DueRange.TODAY -> {
                val dueAt = task.dueAt ?: return false
                dueAt >= todayStartMillis && dueAt < todayEndMillis
            }

            DueRange.NEXT_7_DAYS -> {
                val dueAt = task.dueAt ?: return false
                dueAt >= todayStartMillis && dueAt < next7DaysEndMillis
            }

            DueRange.OVERDUE -> {
                val dueAt = task.dueAt ?: return false
                dueAt < todayStartMillis
            }
        }
    }
}
