package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.RecurrenceKind
import com.liveplan.core.model.RecurrenceRule
import com.liveplan.core.model.Task
import com.liveplan.core.repository.CompletionLogRepository
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
 * Tests for CompleteTaskUseCase
 */
class CompleteTaskUseCaseTest {

    private lateinit var taskRepository: FakeTaskRepository
    private lateinit var completionLogRepository: FakeCompletionLogRepository
    private lateinit var useCase: CompleteTaskUseCase

    private val testProjectId = "project-1"
    private val testDateKey = "2026-02-03"
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
        completionLogRepository = FakeCompletionLogRepository()
        useCase = CompleteTaskUseCase(taskRepository, completionLogRepository)
    }

    // ─────────────────────────────────────
    // oneOff Completion
    // ─────────────────────────────────────

    @Test
    fun `complete oneOff task creates log with ONCE key`() = runBlocking {
        val task = createOneOffTask("task-1", "Buy groceries")
        taskRepository.addTask(task)

        val result = useCase("task-1", testDateKey)

        assertTrue(result.isSuccess)
        val log = result.getOrNull()!!
        assertEquals("task-1", log.taskId)
        assertEquals(CompletionLog.ONCE_KEY, log.occurrenceKey)
        assertTrue(completionLogRepository.hasCompletion("task-1", CompletionLog.ONCE_KEY))
    }

    @Test
    fun `complete oneOff task twice returns duplicate error`() = runBlocking {
        val task = createOneOffTask("task-1", "Buy groceries")
        taskRepository.addTask(task)

        // First completion
        useCase("task-1", testDateKey)

        // Second completion
        val result = useCase("task-1", testDateKey)

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.DuplicateCompletionError)
    }

    // ─────────────────────────────────────
    // habitReset Completion
    // ─────────────────────────────────────

    @Test
    fun `complete habitReset task creates log with dateKey`() = runBlocking {
        val task = createRecurringTask("task-1", "Morning exercise", RecurrenceBehavior.HABIT_RESET)
        taskRepository.addTask(task)

        val result = useCase("task-1", testDateKey)

        assertTrue(result.isSuccess)
        val log = result.getOrNull()!!
        assertEquals("task-1", log.taskId)
        assertEquals(testDateKey, log.occurrenceKey)
    }

    @Test
    fun `complete habitReset task same day twice returns duplicate error`() = runBlocking {
        val task = createRecurringTask("task-1", "Morning exercise", RecurrenceBehavior.HABIT_RESET)
        taskRepository.addTask(task)

        useCase("task-1", testDateKey)
        val result = useCase("task-1", testDateKey)

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.DuplicateCompletionError)
    }

    @Test
    fun `complete habitReset task different days succeeds`() = runBlocking {
        val task = createRecurringTask("task-1", "Morning exercise", RecurrenceBehavior.HABIT_RESET)
        taskRepository.addTask(task)

        val result1 = useCase("task-1", "2026-02-03")
        val result2 = useCase("task-1", "2026-02-04")

        assertTrue(result1.isSuccess)
        assertTrue(result2.isSuccess)
        assertTrue(completionLogRepository.hasCompletion("task-1", "2026-02-03"))
        assertTrue(completionLogRepository.hasCompletion("task-1", "2026-02-04"))
    }

    // ─────────────────────────────────────
    // rollover Completion
    // ─────────────────────────────────────

    @Test
    fun `complete rollover task creates log and advances nextOccurrenceDueAt`() = runBlocking {
        val task = createRecurringTask(
            "task-1", "Weekly report",
            RecurrenceBehavior.ROLLOVER,
            nextOccurrenceDueAt = testNowMillis
        )
        taskRepository.addTask(task)

        val result = useCase("task-1", testDateKey)

        assertTrue(result.isSuccess)
        val log = result.getOrNull()!!
        assertEquals("task-1", log.taskId)
        assertEquals(testDateKey, log.occurrenceKey)

        // Verify task was advanced
        val updatedTask = taskRepository.getTaskById("task-1")!!
        assertNotNull(updatedTask.nextOccurrenceDueAt)
        assertTrue(updatedTask.nextOccurrenceDueAt!! > testNowMillis)
    }

    // ─────────────────────────────────────
    // Error Cases
    // ─────────────────────────────────────

    @Test
    fun `complete non-existent task returns not found error`() = runBlocking {
        val result = useCase("non-existent", testDateKey)

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.NotFoundError)
    }

    // ─────────────────────────────────────
    // Idempotency (taskId, occurrenceKey unique)
    // ─────────────────────────────────────

    @Test
    fun `completion log unique constraint enforced`() = runBlocking {
        val task = createOneOffTask("task-1", "Test")
        taskRepository.addTask(task)

        // Complete once
        val result1 = useCase("task-1", testDateKey)
        assertTrue(result1.isSuccess)

        // Try again
        val result2 = useCase("task-1", testDateKey)
        assertTrue(result2.isFailure)

        // Only one log should exist
        assertEquals(1, completionLogRepository.logs.size)
    }

    // ─────────────────────────────────────
    // Helper Functions
    // ─────────────────────────────────────

    private fun createOneOffTask(id: String, title: String): Task {
        return Task(
            id = id,
            projectId = testProjectId,
            title = title,
            recurrenceRule = null,
            createdAt = testNowMillis
        )
    }

    private fun createRecurringTask(
        id: String,
        title: String,
        behavior: RecurrenceBehavior,
        nextOccurrenceDueAt: Long? = null
    ): Task {
        return Task(
            id = id,
            projectId = testProjectId,
            title = title,
            recurrenceRule = RecurrenceRule(
                kind = RecurrenceKind.DAILY,
                interval = 1,
                anchorDateMillis = testNowMillis - 7 * 24 * 60 * 60 * 1000L
            ),
            recurrenceBehavior = behavior,
            nextOccurrenceDueAt = nextOccurrenceDueAt,
            createdAt = testNowMillis
        )
    }

    // ─────────────────────────────────────
    // Fake Repositories
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

    private class FakeCompletionLogRepository : CompletionLogRepository {
        val logs = mutableListOf<CompletionLog>()
        private val _flow = MutableStateFlow<List<CompletionLog>>(emptyList())

        override fun getAllLogs(): Flow<List<CompletionLog>> = _flow

        override fun getLogsForTask(taskId: String): Flow<List<CompletionLog>> {
            return MutableStateFlow(logs.filter { it.taskId == taskId })
        }

        override suspend fun hasCompletion(taskId: String, occurrenceKey: String): Boolean {
            return logs.any { it.taskId == taskId && it.occurrenceKey == occurrenceKey }
        }

        override suspend fun getCompletion(taskId: String, occurrenceKey: String): CompletionLog? {
            return logs.find { it.taskId == taskId && it.occurrenceKey == occurrenceKey }
        }

        override suspend fun addLog(log: CompletionLog) {
            logs.add(log)
            _flow.value = logs.toList()
        }

        override suspend fun deleteLog(id: String) {
            logs.removeIf { it.id == id }
            _flow.value = logs.toList()
        }

        override suspend fun deleteLogsForTask(taskId: String) {
            logs.removeIf { it.taskId == taskId }
            _flow.value = logs.toList()
        }
    }
}
