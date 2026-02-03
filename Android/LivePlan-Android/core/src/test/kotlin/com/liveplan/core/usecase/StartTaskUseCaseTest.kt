package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
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
 * Tests for StartTaskUseCase
 * - intents.md: StartNextTask workflowState=DOING transition
 * - Idempotency: already DOING -> noop
 */
class StartTaskUseCaseTest {

    private lateinit var taskRepository: FakeTaskRepository
    private lateinit var useCase: StartTaskUseCase

    private val testProjectId = "project-1"
    private val testTaskId = "task-1"
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
        useCase = StartTaskUseCase(taskRepository)
    }

    private suspend fun createTestTask(
        id: String = testTaskId,
        title: String = "Test Task",
        workflowState: WorkflowState = WorkflowState.TODO
    ): Task {
        val task = Task(
            id = id,
            projectId = testProjectId,
            title = title,
            workflowState = workflowState,
            createdAt = testNowMillis
        )
        taskRepository.addTask(task)
        return task
    }

    // ─────────────────────────────────────
    // Success Cases
    // ─────────────────────────────────────

    @Test
    fun `start TODO task transitions to DOING`() = runBlocking {
        createTestTask(workflowState = WorkflowState.TODO)

        val result = useCase(testTaskId)

        assertTrue(result.isSuccess)
        assertEquals(WorkflowState.DOING, result.getOrNull()!!.workflowState)
    }

    @Test
    fun `started task is saved to repository`() = runBlocking {
        createTestTask(workflowState = WorkflowState.TODO)

        useCase(testTaskId)

        val savedTask = taskRepository.getTaskById(testTaskId)
        assertEquals(WorkflowState.DOING, savedTask!!.workflowState)
    }

    @Test
    fun `updatedAt is changed on start`() = runBlocking {
        val task = createTestTask(workflowState = WorkflowState.TODO)
        val originalUpdatedAt = task.updatedAt

        Thread.sleep(10) // ensure time difference

        val result = useCase(testTaskId)

        assertTrue(result.isSuccess)
        assertTrue(result.getOrNull()!!.updatedAt > originalUpdatedAt)
    }

    // ─────────────────────────────────────
    // Idempotency
    // ─────────────────────────────────────

    @Test
    fun `start already DOING task returns success without change`() = runBlocking {
        val task = createTestTask(workflowState = WorkflowState.DOING)

        val result = useCase(testTaskId)

        assertTrue(result.isSuccess)
        assertEquals(WorkflowState.DOING, result.getOrNull()!!.workflowState)
        assertEquals(task.id, result.getOrNull()!!.id)
    }

    @Test
    fun `multiple start calls are idempotent`() = runBlocking {
        createTestTask(workflowState = WorkflowState.TODO)

        val result1 = useCase(testTaskId)
        val result2 = useCase(testTaskId)
        val result3 = useCase(testTaskId)

        assertTrue(result1.isSuccess)
        assertTrue(result2.isSuccess)
        assertTrue(result3.isSuccess)
        assertEquals(WorkflowState.DOING, result1.getOrNull()!!.workflowState)
        assertEquals(WorkflowState.DOING, result2.getOrNull()!!.workflowState)
        assertEquals(WorkflowState.DOING, result3.getOrNull()!!.workflowState)
    }

    // ─────────────────────────────────────
    // Error Cases
    // ─────────────────────────────────────

    @Test
    fun `start non-existent task returns NotFoundError`() = runBlocking {
        val result = useCase("non-existent")

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.NotFoundError)
    }

    @Test
    fun `start completed task returns ValidationError`() = runBlocking {
        createTestTask(workflowState = WorkflowState.DONE)

        val result = useCase(testTaskId)

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.ValidationError)
    }

    // ─────────────────────────────────────
    // Edge Cases
    // ─────────────────────────────────────

    @Test
    fun `start blocked task succeeds`() = runBlocking {
        // Blocked tasks can still be started (direct start is allowed)
        val task = Task(
            id = testTaskId,
            projectId = testProjectId,
            title = "Blocked Task",
            workflowState = WorkflowState.TODO,
            blockedByTaskIds = listOf("other-task"),
            createdAt = testNowMillis
        )
        taskRepository.addTask(task)

        val result = useCase(testTaskId)

        assertTrue(result.isSuccess)
        assertEquals(WorkflowState.DOING, result.getOrNull()!!.workflowState)
        assertTrue(result.getOrNull()!!.isBlocked)
    }

    @Test
    fun `start recurring task succeeds`() = runBlocking {
        val task = Task(
            id = testTaskId,
            projectId = testProjectId,
            title = "Daily Task",
            workflowState = WorkflowState.TODO,
            recurrenceRule = com.liveplan.core.model.RecurrenceRule(
                kind = com.liveplan.core.model.RecurrenceKind.DAILY,
                interval = 1,
                anchorDateMillis = testNowMillis
            ),
            createdAt = testNowMillis
        )
        taskRepository.addTask(task)

        val result = useCase(testTaskId)

        assertTrue(result.isSuccess)
        assertEquals(WorkflowState.DOING, result.getOrNull()!!.workflowState)
        assertTrue(result.getOrNull()!!.isRecurring)
    }

    @Test
    fun `start high priority task succeeds`() = runBlocking {
        val task = Task(
            id = testTaskId,
            projectId = testProjectId,
            title = "Urgent Task",
            priority = com.liveplan.core.model.Priority.P1,
            workflowState = WorkflowState.TODO,
            createdAt = testNowMillis
        )
        taskRepository.addTask(task)

        val result = useCase(testTaskId)

        assertTrue(result.isSuccess)
        assertEquals(WorkflowState.DOING, result.getOrNull()!!.workflowState)
        assertEquals(com.liveplan.core.model.Priority.P1, result.getOrNull()!!.priority)
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
