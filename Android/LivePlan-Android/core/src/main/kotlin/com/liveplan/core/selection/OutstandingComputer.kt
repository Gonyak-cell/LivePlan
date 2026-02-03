package com.liveplan.core.selection

import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.Priority
import com.liveplan.core.model.PrivacyMode
import com.liveplan.core.model.Project
import com.liveplan.core.model.ProjectStatus
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import com.liveplan.core.privacy.PrivacyMasker
import javax.inject.Inject

/**
 * Computes outstanding tasks for lock screen display
 * Aligned with iOS AppCore OutstandingComputer
 *
 * Pure function: no side effects, deterministic output
 */
class OutstandingComputer @Inject constructor(
    private val privacyMasker: PrivacyMasker
) {
    /**
     * Compute lock screen summary
     *
     * @param dateKey Current date key (YYYY-MM-DD)
     * @param pinnedProjectId Pinned project ID (optional)
     * @param privacyMode Privacy mode for masking
     * @param selectionPolicy Selection policy
     * @param projects All projects
     * @param tasks All tasks
     * @param completionLogs All completion logs
     * @param nowMillis Current time in millis (for overdue/dueSoon calculation)
     * @return Lock screen summary with displayList and counters
     */
    fun compute(
        dateKey: String,
        pinnedProjectId: String?,
        privacyMode: PrivacyMode,
        selectionPolicy: SelectionPolicy,
        projects: List<Project>,
        tasks: List<Task>,
        completionLogs: List<CompletionLog>,
        nowMillis: Long = System.currentTimeMillis()
    ): LockScreenSummary {
        // 1. Determine scope
        val (scope, fallbackReason) = determineScope(
            pinnedProjectId, selectionPolicy, projects
        )

        // 2. Filter tasks by scope
        val scopedTasks = filterByScope(tasks, projects, scope, pinnedProjectId)

        // 3. Filter out completed tasks
        val incompleteTasks = filterOutCompleted(scopedTasks, completionLogs, dateKey)

        // 4. Filter out blocked tasks (for displayList, not counters)
        val unblockedTasks = incompleteTasks.filter { !it.isBlocked }

        // 5. Assign priority groups
        val groupedTasks = unblockedTasks.map { task ->
            task to assignGroup(task, nowMillis, dateKey)
        }

        // 6. Sort by group, then tie-breakers
        val sortedTasks = groupedTasks.sortedWith(
            compareBy<Pair<Task, LockScreenSummary.PriorityGroup>> { it.second.ordinal }
                .thenBy { it.first.dueAt ?: Long.MAX_VALUE }
                .thenBy { it.first.priority.value }
                .thenBy { it.first.createdAt }
                .thenBy { it.first.id }
        )

        // 7. Take Top 3
        val top3 = sortedTasks.take(3).map { (task, group) ->
            LockScreenSummary.DisplayTask(
                task = task,
                maskedTitle = privacyMasker.maskTitle(task.title, privacyMode),
                group = group
            )
        }

        // 8. Calculate counters (from all incomplete tasks, including blocked)
        val counters = calculateCounters(incompleteTasks, nowMillis, dateKey)

        return LockScreenSummary(
            displayList = top3,
            counters = counters,
            metadata = LockScreenSummary.Metadata(
                dateKey = dateKey,
                scope = scope,
                fallbackReason = fallbackReason
            )
        )
    }

    private fun determineScope(
        pinnedProjectId: String?,
        selectionPolicy: SelectionPolicy,
        projects: List<Project>
    ): Pair<LockScreenSummary.Scope, LockScreenSummary.FallbackReason?> {
        return when (selectionPolicy) {
            SelectionPolicy.TODAY_OVERVIEW -> {
                LockScreenSummary.Scope.TODAY_OVERVIEW to null
            }
            SelectionPolicy.PINNED_FIRST, SelectionPolicy.AUTO -> {
                if (pinnedProjectId == null) {
                    LockScreenSummary.Scope.TODAY_OVERVIEW to
                        LockScreenSummary.FallbackReason.NO_PINNED_PROJECT
                } else {
                    val pinnedProject = projects.find { it.id == pinnedProjectId }
                    if (pinnedProject == null || pinnedProject.status != ProjectStatus.ACTIVE) {
                        LockScreenSummary.Scope.TODAY_OVERVIEW to
                            LockScreenSummary.FallbackReason.PINNED_NOT_ACTIVE
                    } else {
                        LockScreenSummary.Scope.PINNED_PROJECT to null
                    }
                }
            }
        }
    }

    private fun filterByScope(
        tasks: List<Task>,
        projects: List<Project>,
        scope: LockScreenSummary.Scope,
        pinnedProjectId: String?
    ): List<Task> {
        val activeProjectIds = projects
            .filter { it.status == ProjectStatus.ACTIVE }
            .map { it.id }
            .toSet()

        return when (scope) {
            LockScreenSummary.Scope.PINNED_PROJECT -> {
                tasks.filter { it.projectId == pinnedProjectId }
            }
            LockScreenSummary.Scope.TODAY_OVERVIEW -> {
                tasks.filter { it.projectId in activeProjectIds }
            }
        }
    }

    private fun filterOutCompleted(
        tasks: List<Task>,
        completionLogs: List<CompletionLog>,
        dateKey: String
    ): List<Task> {
        return tasks.filter { task ->
            !isCompleted(task, completionLogs, dateKey)
        }
    }

    private fun isCompleted(
        task: Task,
        completionLogs: List<CompletionLog>,
        dateKey: String
    ): Boolean {
        return if (task.isOneOff) {
            // oneOff: check for "once" occurrence
            completionLogs.any {
                it.taskId == task.id && it.occurrenceKey == CompletionLog.ONCE_KEY
            }
        } else {
            // recurring: check based on behavior
            when (task.recurrenceBehavior) {
                RecurrenceBehavior.HABIT_RESET -> {
                    // habitReset: check today's dateKey
                    completionLogs.any {
                        it.taskId == task.id && it.occurrenceKey == dateKey
                    }
                }
                RecurrenceBehavior.ROLLOVER -> {
                    // rollover: check current occurrence's dateKey
                    val occurrenceKey = task.nextOccurrenceDueAt?.let {
                        millisToDateKey(it)
                    } ?: dateKey
                    completionLogs.any {
                        it.taskId == task.id && it.occurrenceKey == occurrenceKey
                    }
                }
            }
        }
    }

    private fun assignGroup(
        task: Task,
        nowMillis: Long,
        dateKey: String
    ): LockScreenSummary.PriorityGroup {
        // G1: DOING
        if (task.workflowState == WorkflowState.DOING) {
            return LockScreenSummary.PriorityGroup.G1_DOING
        }

        // G2: Overdue
        val dueAt = task.dueAt
        if (dueAt != null && dueAt < nowMillis) {
            return LockScreenSummary.PriorityGroup.G2_OVERDUE
        }

        // G3: Due soon (within 24h)
        val twentyFourHours = 24 * 60 * 60 * 1000L
        if (dueAt != null && dueAt >= nowMillis && (dueAt - nowMillis) <= twentyFourHours) {
            return LockScreenSummary.PriorityGroup.G3_DUE_SOON
        }

        // G4: P1 priority
        if (task.priority == Priority.P1) {
            return LockScreenSummary.PriorityGroup.G4_P1
        }

        // G5: Habit reset recurring (today incomplete already filtered)
        if (task.isRecurring && task.recurrenceBehavior == RecurrenceBehavior.HABIT_RESET) {
            return LockScreenSummary.PriorityGroup.G5_HABIT_TODAY
        }

        // G6: Other
        return LockScreenSummary.PriorityGroup.G6_OTHER
    }

    private fun calculateCounters(
        incompleteTasks: List<Task>,
        nowMillis: Long,
        dateKey: String
    ): LockScreenSummary.Counters {
        val twentyFourHours = 24 * 60 * 60 * 1000L

        var overdueCount = 0
        var dueSoonCount = 0
        var p1Count = 0
        var doingCount = 0
        var blockedCount = 0
        var recurringTotal = 0

        for (task in incompleteTasks) {
            if (task.isBlocked) blockedCount++
            if (task.workflowState == WorkflowState.DOING) doingCount++
            if (task.priority == Priority.P1) p1Count++
            if (task.isRecurring) recurringTotal++

            val dueAt = task.dueAt
            if (dueAt != null) {
                if (dueAt < nowMillis) {
                    overdueCount++
                } else if ((dueAt - nowMillis) <= twentyFourHours) {
                    dueSoonCount++
                }
            }
        }

        return LockScreenSummary.Counters(
            outstandingTotal = incompleteTasks.size,
            overdueCount = overdueCount,
            dueSoonCount = dueSoonCount,
            recurringDone = 0, // Calculated separately if needed
            recurringTotal = recurringTotal,
            p1Count = p1Count,
            doingCount = doingCount,
            blockedCount = blockedCount
        )
    }

    private fun millisToDateKey(millis: Long): String {
        val calendar = java.util.Calendar.getInstance().apply {
            timeInMillis = millis
        }
        val year = calendar.get(java.util.Calendar.YEAR)
        val month = calendar.get(java.util.Calendar.MONTH) + 1
        val day = calendar.get(java.util.Calendar.DAY_OF_MONTH)
        return "%04d-%02d-%02d".format(year, month, day)
    }
}
