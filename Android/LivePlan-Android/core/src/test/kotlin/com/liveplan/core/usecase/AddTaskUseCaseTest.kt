package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.Priority
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.RecurrenceKind
import com.liveplan.core.model.RecurrenceRule
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import com.liveplan.core.repository.TaskRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/**
 * Tests for AddTaskUseCase
 * - testing.md A1: AppCore unit tests required
 * - data-model.md A4: Task Phase 2 field support
 */
class AddTaskUseCaseTest {

    private lateinit var taskRepository: FakeTaskRepository
    private lateinit var useCase: AddTaskUseCase

    private val testProjectId = "project-1"
    private val testNowMillis: Long

    init {
        val calendar = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 3, 10, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        testNowMillis = calendar.timeInMillis
    }

    @Before
    fun setUp() {
        taskRepository = FakeTaskRepository()
        useCase = AddTaskUseCase(taskRepository)
    }

    // ─────────────────────────────────────
    // Basic Task Creation
    // ─────────────────────────────────────

    @Test
    fun `create basic task succeeds`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = "New Task"
        )

        assertTrue(result.isSuccess)
        val task = result.getOrNull()!!
        assertEquals("New Task", task.title)
        assertEquals(testProjectId, task.projectId)
        assertEquals(Priority.DEFAULT, task.priority)
        assertEquals(WorkflowState.DEFAULT, task.workflowState)
        assertTrue(task.isOneOff)
    }

    @Test
    fun `title is trimmed`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = "  Trimmed Title  "
        )

        assertTrue(result.isSuccess)
        assertEquals("Trimmed Title", result.getOrNull()!!.title)
    }

    @Test
    fun `empty title returns EmptyTitleError`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = ""
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.EmptyTitleError)
    }

    @Test
    fun `whitespace only title returns EmptyTitleError`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = "   "
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.EmptyTitleError)
    }

    // ─────────────────────────────────────
    // Priority (Phase 2)
    // ─────────────────────────────────────

    @Test
    fun `create task with priority P1`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = "Urgent Task",
            priority = Priority.P1
        )

        assertTrue(result.isSuccess)
        assertEquals(Priority.P1, result.getOrNull()!!.priority)
    }

    @Test
    fun `default priority is P4`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = "Normal Task"
        )

        assertTrue(result.isSuccess)
        assertEquals(Priority.P4, result.getOrNull()!!.priority)
    }

    // ─────────────────────────────────────
    // Due Date
    // ─────────────────────────────────────

    @Test
    fun `create task with due date`() = runBlocking {
        val dueAt = testNowMillis + 24 * 60 * 60 * 1000L // tomorrow

        val result = useCase(
            projectId = testProjectId,
            title = "Task with Due",
            dueAt = dueAt
        )

        assertTrue(result.isSuccess)
        assertEquals(dueAt, result.getOrNull()!!.dueAt)
    }

    // ─────────────────────────────────────
    // Recurrence
    // ─────────────────────────────────────

    @Test
    fun `create recurring task with habitReset`() = runBlocking {
        val recurrenceRule = RecurrenceRule(
            kind = RecurrenceKind.DAILY,
            interval = 1,
            anchorDateMillis = testNowMillis
        )

        val result = useCase(
            projectId = testProjectId,
            title = "Daily Task",
            recurrenceRule = recurrenceRule,
            recurrenceBehavior = RecurrenceBehavior.HABIT_RESET
        )

        assertTrue(result.isSuccess)
        val task = result.getOrNull()!!
        assertTrue(task.isRecurring)
        assertEquals(RecurrenceBehavior.HABIT_RESET, task.recurrenceBehavior)
        assertNull(task.nextOccurrenceDueAt)
    }

    @Test
    fun `create recurring task with rollover sets nextOccurrenceDueAt`() = runBlocking {
        val recurrenceRule = RecurrenceRule(
            kind = RecurrenceKind.DAILY,
            interval = 1,
            anchorDateMillis = testNowMillis
        )
        val dueAt = testNowMillis + 24 * 60 * 60 * 1000L

        val result = useCase(
            projectId = testProjectId,
            title = "Rollover Task",
            recurrenceRule = recurrenceRule,
            recurrenceBehavior = RecurrenceBehavior.ROLLOVER,
            dueAt = dueAt
        )

        assertTrue(result.isSuccess)
        val task = result.getOrNull()!!
        assertEquals(RecurrenceBehavior.ROLLOVER, task.recurrenceBehavior)
        assertEquals(dueAt, task.nextOccurrenceDueAt)
    }

    // ─────────────────────────────────────
    // Tags (Phase 2)
    // ─────────────────────────────────────

    @Test
    fun `create task with tags`() = runBlocking {
        val tagIds = listOf("tag1", "tag2", "tag3")

        val result = useCase(
            projectId = testProjectId,
            title = "Tagged Task",
            tagIds = tagIds
        )

        assertTrue(result.isSuccess)
        assertEquals(tagIds, result.getOrNull()!!.tagIds)
    }

    @Test
    fun `create task without tags has empty list`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = "Untagged Task"
        )

        assertTrue(result.isSuccess)
        assertTrue(result.getOrNull()!!.tagIds.isEmpty())
    }

    // ─────────────────────────────────────
    // Section (Phase 2)
    // ─────────────────────────────────────

    @Test
    fun `create task with section`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = "Task in Section",
            sectionId = "section-1"
        )

        assertTrue(result.isSuccess)
        assertEquals("section-1", result.getOrNull()!!.sectionId)
    }

    @Test
    fun `create task without section is uncategorized`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = "Uncategorized Task"
        )

        assertTrue(result.isSuccess)
        assertNull(result.getOrNull()!!.sectionId)
    }

    // ─────────────────────────────────────
    // Note (Phase 2)
    // ─────────────────────────────────────

    @Test
    fun `create task with note`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = "Task with Note",
            note = "Detailed description"
        )

        assertTrue(result.isSuccess)
        assertEquals("Detailed description", result.getOrNull()!!.note)
    }

    // ─────────────────────────────────────
    // All Fields Combined
    // ─────────────────────────────────────

    @Test
    fun `create task with all Phase 2 fields`() = runBlocking {
        val recurrenceRule = RecurrenceRule(
            kind = RecurrenceKind.DAILY,
            interval = 1,
            anchorDateMillis = testNowMillis
        )
        val dueAt = testNowMillis + 24 * 60 * 60 * 1000L

        val result = useCase(
            projectId = testProjectId,
            title = "Full Featured Task",
            priority = Priority.P1,
            dueAt = dueAt,
            recurrenceRule = recurrenceRule,
            recurrenceBehavior = RecurrenceBehavior.HABIT_RESET,
            sectionId = "section-1",
            tagIds = listOf("urgent", "work"),
            note = "Important task notes"
        )

        assertTrue(result.isSuccess)
        val task = result.getOrNull()!!
        assertEquals("Full Featured Task", task.title)
        assertEquals(testProjectId, task.projectId)
        assertEquals(Priority.P1, task.priority)
        assertEquals(dueAt, task.dueAt)
        assertTrue(task.isRecurring)
        assertEquals("section-1", task.sectionId)
        assertEquals(listOf("urgent", "work"), task.tagIds)
        assertEquals("Important task notes", task.note)
    }

    // ─────────────────────────────────────
    // Persistence
    // ─────────────────────────────────────

    @Test
    fun `created task is saved to repository`() = runBlocking {
        val result = useCase(
            projectId = testProjectId,
            title = "Saved Task"
        )

        assertTrue(result.isSuccess)
        val task = result.getOrNull()!!

        val savedTask = taskRepository.getTaskById(task.id)
        assertNotNull(savedTask)
        assertEquals("Saved Task", savedTask!!.title)
    }

    // ─────────────────────────────────────
    // Fake Repository
    // ─────────────────────────────────────

    private class FakeTaskRepository : TaskRepository {
        private val tasks = mutableMapOf<String, Task>()
        private val _flow = MutableStateFlow<List<Task>>(emptyList())

        override fun getAllTasks(): Flow<List<Task>> = _flow

        override fun getTasksByProject(projectId: String): Flow<List<Task>> {
            return MutableStateFlow(tasks.values.filter { it.projectId == projectId })
        }

        override suspend fun getTaskById(id: String): Task? = tasks[id]

        override suspend fun addTask(task: Task) {
            tasks[task.id] = task
            _flow.value = tasks.values.toList()
        }

        override suspend fun updateTask(task: Task) {
            tasks[task.id] = task
            _flow.value = tasks.values.toList()
        }

        override suspend fun deleteTask(id: String) {
            tasks.remove(id)
            _flow.value = tasks.values.toList()
        }

        override suspend fun getTasksByIds(ids: List<String>): List<Task> {
            return ids.mapNotNull { tasks[it] }
        }
    }
}
