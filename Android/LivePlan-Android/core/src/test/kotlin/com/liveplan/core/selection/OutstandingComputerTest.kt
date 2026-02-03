package com.liveplan.core.selection

import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.Priority
import com.liveplan.core.model.PrivacyMode
import com.liveplan.core.model.Project
import com.liveplan.core.model.ProjectStatus
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.RecurrenceKind
import com.liveplan.core.model.RecurrenceRule
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import com.liveplan.core.privacy.PrivacyMasker
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/**
 * Tests for OutstandingComputer
 * Covers: oneOff/recurring completion, priority groups, counters
 */
class OutstandingComputerTest {

    private lateinit var computer: OutstandingComputer
    private lateinit var privacyMasker: PrivacyMasker

    private val testProjectId = "project-1"
    private val testDateKey = "2026-02-03"
    private val testNowMillis: Long

    init {
        // Set up test time: 2026-02-03 10:00:00
        val calendar = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 3, 10, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        testNowMillis = calendar.timeInMillis
    }

    @Before
    fun setUp() {
        privacyMasker = PrivacyMasker()
        computer = OutstandingComputer(privacyMasker)
    }

    // ─────────────────────────────────────
    // B1: oneOff completion (permanent removal)
    // ─────────────────────────────────────

    @Test
    fun `oneOff task - incomplete shows in outstanding`() {
        val task = createOneOffTask("task-1", "Buy groceries")
        val projects = listOf(createProject(testProjectId))
        val logs = emptyList<CompletionLog>()

        val result = compute(projects, listOf(task), logs)

        assertEquals(1, result.counters.outstandingTotal)
        assertEquals(1, result.displayList.size)
        assertEquals("task-1", result.displayList[0].task.id)
    }

    @Test
    fun `oneOff task - completed removed from outstanding`() {
        val task = createOneOffTask("task-1", "Buy groceries")
        val projects = listOf(createProject(testProjectId))
        val logs = listOf(CompletionLog.forOneOff("task-1"))

        val result = compute(projects, listOf(task), logs)

        assertEquals(0, result.counters.outstandingTotal)
        assertEquals(0, result.displayList.size)
    }

    @Test
    fun `oneOff task - duplicate completion is idempotent`() {
        val task = createOneOffTask("task-1", "Buy groceries")
        val projects = listOf(createProject(testProjectId))
        // Multiple logs for same task (shouldn't happen, but test robustness)
        val logs = listOf(
            CompletionLog.forOneOff("task-1"),
            CompletionLog.forOneOff("task-1")
        )

        val result = compute(projects, listOf(task), logs)

        assertEquals(0, result.counters.outstandingTotal)
    }

    // ─────────────────────────────────────
    // B2: recurring habitReset completion (today only)
    // ─────────────────────────────────────

    @Test
    fun `habitReset recurring - incomplete today shows in outstanding`() {
        val task = createRecurringTask("task-1", "Morning exercise", RecurrenceBehavior.HABIT_RESET)
        val projects = listOf(createProject(testProjectId))
        val logs = emptyList<CompletionLog>()

        val result = compute(projects, listOf(task), logs)

        assertEquals(1, result.counters.outstandingTotal)
        assertEquals(1, result.counters.recurringTotal)
        assertEquals(1, result.displayList.size)
    }

    @Test
    fun `habitReset recurring - completed today removed from outstanding`() {
        val task = createRecurringTask("task-1", "Morning exercise", RecurrenceBehavior.HABIT_RESET)
        val projects = listOf(createProject(testProjectId))
        val logs = listOf(CompletionLog.forHabitReset("task-1", testDateKey))

        val result = compute(projects, listOf(task), logs)

        assertEquals(0, result.counters.outstandingTotal)
        assertEquals(0, result.displayList.size)
    }

    @Test
    fun `habitReset recurring - yesterday completion does not affect today`() {
        val task = createRecurringTask("task-1", "Morning exercise", RecurrenceBehavior.HABIT_RESET)
        val projects = listOf(createProject(testProjectId))
        // Completed yesterday (2026-02-02)
        val logs = listOf(CompletionLog.forHabitReset("task-1", "2026-02-02"))

        val result = compute(projects, listOf(task), logs)

        // Should show as incomplete today
        assertEquals(1, result.counters.outstandingTotal)
        assertEquals(1, result.displayList.size)
    }

    // ─────────────────────────────────────
    // B3: recurring rollover completion
    // ─────────────────────────────────────

    @Test
    fun `rollover recurring - incomplete shows in outstanding`() {
        val nextDueMillis = testNowMillis + 24 * 60 * 60 * 1000L // Tomorrow
        val task = createRecurringTask(
            "task-1", "Weekly report",
            RecurrenceBehavior.ROLLOVER,
            nextOccurrenceDueAt = nextDueMillis
        )
        val projects = listOf(createProject(testProjectId))
        val logs = emptyList<CompletionLog>()

        val result = compute(projects, listOf(task), logs)

        assertEquals(1, result.counters.outstandingTotal)
    }

    @Test
    fun `rollover recurring - overdue shows in outstanding with overdue count`() {
        val pastDueMillis = testNowMillis - 24 * 60 * 60 * 1000L // Yesterday
        val task = createRecurringTask(
            "task-1", "Weekly report",
            RecurrenceBehavior.ROLLOVER,
            nextOccurrenceDueAt = pastDueMillis
        ).copy(dueAt = pastDueMillis)
        val projects = listOf(createProject(testProjectId))
        val logs = emptyList<CompletionLog>()

        val result = compute(projects, listOf(task), logs)

        assertEquals(1, result.counters.outstandingTotal)
        assertEquals(1, result.counters.overdueCount)
    }

    // ─────────────────────────────────────
    // Priority Groups
    // ─────────────────────────────────────

    @Test
    fun `G1_DOING takes priority over other groups`() {
        val doingTask = createOneOffTask("task-1", "In progress").copy(workflowState = WorkflowState.DOING)
        val p1Task = createOneOffTask("task-2", "Important").copy(priority = Priority.P1)
        val projects = listOf(createProject(testProjectId))

        val result = compute(projects, listOf(doingTask, p1Task), emptyList())

        assertEquals(2, result.displayList.size)
        assertEquals("task-1", result.displayList[0].task.id)
        assertEquals(LockScreenSummary.PriorityGroup.G1_DOING, result.displayList[0].group)
    }

    @Test
    fun `G2_OVERDUE takes priority after DOING`() {
        val overdueTask = createOneOffTask("task-1", "Overdue").copy(
            dueAt = testNowMillis - 1000
        )
        val normalTask = createOneOffTask("task-2", "Normal")
        val projects = listOf(createProject(testProjectId))

        val result = compute(projects, listOf(overdueTask, normalTask), emptyList())

        assertEquals("task-1", result.displayList[0].task.id)
        assertEquals(LockScreenSummary.PriorityGroup.G2_OVERDUE, result.displayList[0].group)
    }

    @Test
    fun `G3_DUE_SOON within 24 hours`() {
        val dueSoonTask = createOneOffTask("task-1", "Due soon").copy(
            dueAt = testNowMillis + 12 * 60 * 60 * 1000L // 12 hours from now
        )
        val normalTask = createOneOffTask("task-2", "Normal")
        val projects = listOf(createProject(testProjectId))

        val result = compute(projects, listOf(dueSoonTask, normalTask), emptyList())

        assertEquals("task-1", result.displayList[0].task.id)
        assertEquals(LockScreenSummary.PriorityGroup.G3_DUE_SOON, result.displayList[0].group)
    }

    @Test
    fun `G4_P1 priority tasks`() {
        val p1Task = createOneOffTask("task-1", "P1").copy(priority = Priority.P1)
        val p4Task = createOneOffTask("task-2", "P4").copy(priority = Priority.P4)
        val projects = listOf(createProject(testProjectId))

        val result = compute(projects, listOf(p1Task, p4Task), emptyList())

        assertEquals("task-1", result.displayList[0].task.id)
        assertEquals(LockScreenSummary.PriorityGroup.G4_P1, result.displayList[0].group)
    }

    @Test
    fun `G5_HABIT_TODAY for habitReset recurring`() {
        val habitTask = createRecurringTask("task-1", "Daily habit", RecurrenceBehavior.HABIT_RESET)
        val normalTask = createOneOffTask("task-2", "Normal")
        val projects = listOf(createProject(testProjectId))

        val result = compute(projects, listOf(habitTask, normalTask), emptyList())

        assertEquals("task-1", result.displayList[0].task.id)
        assertEquals(LockScreenSummary.PriorityGroup.G5_HABIT_TODAY, result.displayList[0].group)
    }

    // ─────────────────────────────────────
    // Blocked Tasks
    // ─────────────────────────────────────

    @Test
    fun `blocked tasks excluded from displayList`() {
        val blockerTask = createOneOffTask("task-1", "Blocker")
        val blockedTask = createOneOffTask("task-2", "Blocked").copy(
            blockedByTaskIds = listOf("task-1")
        )
        val projects = listOf(createProject(testProjectId))

        val result = compute(projects, listOf(blockerTask, blockedTask), emptyList())

        assertEquals(2, result.counters.outstandingTotal)
        assertEquals(1, result.counters.blockedCount)
        assertEquals(1, result.displayList.size)
        assertEquals("task-1", result.displayList[0].task.id)
    }

    // ─────────────────────────────────────
    // Counters
    // ─────────────────────────────────────

    @Test
    fun `counters calculated correctly`() {
        val doingTask = createOneOffTask("task-1", "Doing").copy(workflowState = WorkflowState.DOING)
        val overdueTask = createOneOffTask("task-2", "Overdue").copy(dueAt = testNowMillis - 1000)
        val dueSoonTask = createOneOffTask("task-3", "Due soon").copy(
            dueAt = testNowMillis + 12 * 60 * 60 * 1000L
        )
        val p1Task = createOneOffTask("task-4", "P1").copy(priority = Priority.P1)
        val recurringTask = createRecurringTask("task-5", "Recurring", RecurrenceBehavior.HABIT_RESET)
        val blockedTask = createOneOffTask("task-6", "Blocked").copy(blockedByTaskIds = listOf("task-1"))
        val projects = listOf(createProject(testProjectId))
        val tasks = listOf(doingTask, overdueTask, dueSoonTask, p1Task, recurringTask, blockedTask)

        val result = compute(projects, tasks, emptyList())

        assertEquals(6, result.counters.outstandingTotal)
        assertEquals(1, result.counters.overdueCount)
        assertEquals(1, result.counters.dueSoonCount)
        assertEquals(1, result.counters.p1Count)
        assertEquals(1, result.counters.doingCount)
        assertEquals(1, result.counters.blockedCount)
        assertEquals(1, result.counters.recurringTotal)
    }

    // ─────────────────────────────────────
    // Scope and Fallback
    // ─────────────────────────────────────

    @Test
    fun `pinned project scope filters tasks`() {
        val pinnedProject = createProject("pinned-project")
        val otherProject = createProject("other-project")
        val pinnedTask = createOneOffTask("task-1", "Pinned", projectId = "pinned-project")
        val otherTask = createOneOffTask("task-2", "Other", projectId = "other-project")

        val result = computer.compute(
            dateKey = testDateKey,
            pinnedProjectId = "pinned-project",
            privacyMode = PrivacyMode.LEVEL_0,
            selectionPolicy = SelectionPolicy.PINNED_FIRST,
            projects = listOf(pinnedProject, otherProject),
            tasks = listOf(pinnedTask, otherTask),
            completionLogs = emptyList(),
            nowMillis = testNowMillis
        )

        assertEquals(1, result.counters.outstandingTotal)
        assertEquals("task-1", result.displayList[0].task.id)
        assertEquals(LockScreenSummary.Scope.PINNED_PROJECT, result.metadata.scope)
    }

    @Test
    fun `fallback to today overview when no pinned project`() {
        val project = createProject(testProjectId)
        val task = createOneOffTask("task-1", "Task")

        val result = computer.compute(
            dateKey = testDateKey,
            pinnedProjectId = null,
            privacyMode = PrivacyMode.LEVEL_0,
            selectionPolicy = SelectionPolicy.PINNED_FIRST,
            projects = listOf(project),
            tasks = listOf(task),
            completionLogs = emptyList(),
            nowMillis = testNowMillis
        )

        assertEquals(LockScreenSummary.Scope.TODAY_OVERVIEW, result.metadata.scope)
        assertEquals(LockScreenSummary.FallbackReason.NO_PINNED_PROJECT, result.metadata.fallbackReason)
    }

    @Test
    fun `fallback when pinned project is archived`() {
        val archivedProject = createProject("pinned").copy(status = ProjectStatus.ARCHIVED)
        val activeProject = createProject("active")
        val archivedTask = createOneOffTask("task-1", "Archived", projectId = "pinned")
        val activeTask = createOneOffTask("task-2", "Active", projectId = "active")

        val result = computer.compute(
            dateKey = testDateKey,
            pinnedProjectId = "pinned",
            privacyMode = PrivacyMode.LEVEL_0,
            selectionPolicy = SelectionPolicy.PINNED_FIRST,
            projects = listOf(archivedProject, activeProject),
            tasks = listOf(archivedTask, activeTask),
            completionLogs = emptyList(),
            nowMillis = testNowMillis
        )

        assertEquals(LockScreenSummary.Scope.TODAY_OVERVIEW, result.metadata.scope)
        assertEquals(LockScreenSummary.FallbackReason.PINNED_NOT_ACTIVE, result.metadata.fallbackReason)
        assertEquals(1, result.counters.outstandingTotal) // Only active project task
    }

    // ─────────────────────────────────────
    // Top N Limit
    // ─────────────────────────────────────

    @Test
    fun `displayList limited to top 3`() {
        val tasks = (1..10).map { createOneOffTask("task-$it", "Task $it") }
        val projects = listOf(createProject(testProjectId))

        val result = compute(projects, tasks, emptyList())

        assertEquals(10, result.counters.outstandingTotal)
        assertEquals(3, result.displayList.size)
    }

    // ─────────────────────────────────────
    // Helper Functions
    // ─────────────────────────────────────

    private fun compute(
        projects: List<Project>,
        tasks: List<Task>,
        logs: List<CompletionLog>
    ): LockScreenSummary {
        return computer.compute(
            dateKey = testDateKey,
            pinnedProjectId = testProjectId,
            privacyMode = PrivacyMode.LEVEL_0,
            selectionPolicy = SelectionPolicy.PINNED_FIRST,
            projects = projects,
            tasks = tasks,
            completionLogs = logs,
            nowMillis = testNowMillis
        )
    }

    private fun createProject(id: String): Project {
        return Project(
            id = id,
            title = "Test Project",
            startDate = testNowMillis - 7 * 24 * 60 * 60 * 1000L,
            status = ProjectStatus.ACTIVE
        )
    }

    private fun createOneOffTask(
        id: String,
        title: String,
        projectId: String = testProjectId
    ): Task {
        return Task(
            id = id,
            projectId = projectId,
            title = title,
            recurrenceRule = null
        )
    }

    private fun createRecurringTask(
        id: String,
        title: String,
        behavior: RecurrenceBehavior,
        projectId: String = testProjectId,
        nextOccurrenceDueAt: Long? = null
    ): Task {
        return Task(
            id = id,
            projectId = projectId,
            title = title,
            recurrenceRule = RecurrenceRule(
                kind = RecurrenceKind.DAILY,
                interval = 1,
                anchorDate = testNowMillis - 7 * 24 * 60 * 60 * 1000L
            ),
            recurrenceBehavior = behavior,
            nextOccurrenceDueAt = nextOccurrenceDueAt
        )
    }
}
