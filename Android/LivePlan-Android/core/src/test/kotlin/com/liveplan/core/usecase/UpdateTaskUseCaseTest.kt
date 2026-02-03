package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.Priority
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
 * Tests for UpdateTaskUseCase
 * - testing.md A1: AppCore unit tests required
 * - data-model.md A4: Task Phase 2 field update validation
 */
class UpdateTaskUseCaseTest {

    private lateinit var taskRepository: FakeTaskRepository
    private lateinit var useCase: UpdateTaskUseCase

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
        useCase = UpdateTaskUseCase(taskRepository)
    }

    private suspend fun createTestTask(
        id: String = testTaskId,
        title: String = "Test Task",
        priority: Priority = Priority.P4,
        workflowState: WorkflowState = WorkflowState.TODO
    ): Task {
        val task = Task(
            id = id,
            projectId = testProjectId,
            title = title,
            priority = priority,
            workflowState = workflowState,
            createdAt = testNowMillis
        )
        taskRepository.addTask(task)
        return task
    }

    // ─────────────────────────────────────
    // Title Update
    // ─────────────────────────────────────

    @Test
    fun `update title succeeds`() = runBlocking {
        createTestTask()

        val result = useCase(
            taskId = testTaskId,
            title = "Updated Title"
        )

        assertTrue(result.isSuccess)
        assertEquals("Updated Title", result.getOrNull()!!.title)
    }

    @Test
    fun `update title is trimmed`() = runBlocking {
        createTestTask()

        val result = useCase(
            taskId = testTaskId,
            title = "  Trimmed Title  "
        )

        assertTrue(result.isSuccess)
        assertEquals("Trimmed Title", result.getOrNull()!!.title)
    }

    // ─────────────────────────────────────
    // Priority Update (Phase 2)
    // ─────────────────────────────────────

    @Test
    fun `update priority to P1`() = runBlocking {
        createTestTask(priority = Priority.P4)

        val result = useCase(
            taskId = testTaskId,
            priority = Priority.P1
        )

        assertTrue(result.isSuccess)
        assertEquals(Priority.P1, result.getOrNull()!!.priority)
    }

    // ─────────────────────────────────────
    // WorkflowState Update (Phase 2)
    // ─────────────────────────────────────

    @Test
    fun `update workflowState to DOING`() = runBlocking {
        createTestTask(workflowState = WorkflowState.TODO)

        val result = useCase(
            taskId = testTaskId,
            workflowState = WorkflowState.DOING
        )

        assertTrue(result.isSuccess)
        assertEquals(WorkflowState.DOING, result.getOrNull()!!.workflowState)
    }

    @Test
    fun `update workflowState to DONE`() = runBlocking {
        createTestTask(workflowState = WorkflowState.DOING)

        val result = useCase(
            taskId = testTaskId,
            workflowState = WorkflowState.DONE
        )

        assertTrue(result.isSuccess)
        assertEquals(WorkflowState.DONE, result.getOrNull()!!.workflowState)
    }

    // ─────────────────────────────────────
    // Due Date Update
    // ─────────────────────────────────────

    @Test
    fun `update dueAt succeeds`() = runBlocking {
        createTestTask()
        val newDueAt = testNowMillis + 24 * 60 * 60 * 1000L

        val result = useCase(
            taskId = testTaskId,
            dueAt = newDueAt
        )

        assertTrue(result.isSuccess)
        assertEquals(newDueAt, result.getOrNull()!!.dueAt)
    }

    @Test
    fun `clear dueAt succeeds`() = runBlocking {
        val task = Task(
            id = testTaskId,
            projectId = testProjectId,
            title = "Test",
            dueAt = testNowMillis + 24 * 60 * 60 * 1000L,
            createdAt = testNowMillis
        )
        taskRepository.addTask(task)

        val result = useCase(
            taskId = testTaskId,
            clearDueAt = true
        )

        assertTrue(result.isSuccess)
        assertNull(result.getOrNull()!!.dueAt)
    }

    // ─────────────────────────────────────
    // Tags Update (Phase 2)
    // ─────────────────────────────────────

    @Test
    fun `update tagIds`() = runBlocking {
        createTestTask()

        val result = useCase(
            taskId = testTaskId,
            tagIds = listOf("tag1", "tag2")
        )

        assertTrue(result.isSuccess)
        assertEquals(listOf("tag1", "tag2"), result.getOrNull()!!.tagIds)
    }

    @Test
    fun `clear tagIds by setting empty list`() = runBlocking {
        val task = Task(
            id = testTaskId,
            projectId = testProjectId,
            title = "Test",
            tagIds = listOf("tag1", "tag2"),
            createdAt = testNowMillis
        )
        taskRepository.addTask(task)

        val result = useCase(
            taskId = testTaskId,
            tagIds = emptyList()
        )

        assertTrue(result.isSuccess)
        assertTrue(result.getOrNull()!!.tagIds.isEmpty())
    }

    // ─────────────────────────────────────
    // Section Update (Phase 2)
    // ─────────────────────────────────────

    @Test
    fun `update sectionId`() = runBlocking {
        createTestTask()

        val result = useCase(
            taskId = testTaskId,
            sectionId = "section-1"
        )

        assertTrue(result.isSuccess)
        assertEquals("section-1", result.getOrNull()!!.sectionId)
    }

    @Test
    fun `clear sectionId succeeds`() = runBlocking {
        val task = Task(
            id = testTaskId,
            projectId = testProjectId,
            title = "Test",
            sectionId = "section-1",
            createdAt = testNowMillis
        )
        taskRepository.addTask(task)

        val result = useCase(
            taskId = testTaskId,
            clearSectionId = true
        )

        assertTrue(result.isSuccess)
        assertNull(result.getOrNull()!!.sectionId)
    }

    // ─────────────────────────────────────
    // Note Update (Phase 2)
    // ─────────────────────────────────────

    @Test
    fun `update note`() = runBlocking {
        createTestTask()

        val result = useCase(
            taskId = testTaskId,
            note = "New note content"
        )

        assertTrue(result.isSuccess)
        assertEquals("New note content", result.getOrNull()!!.note)
    }

    @Test
    fun `clear note succeeds`() = runBlocking {
        val task = Task(
            id = testTaskId,
            projectId = testProjectId,
            title = "Test",
            note = "Old note",
            createdAt = testNowMillis
        )
        taskRepository.addTask(task)

        val result = useCase(
            taskId = testTaskId,
            clearNote = true
        )

        assertTrue(result.isSuccess)
        assertNull(result.getOrNull()!!.note)
    }

    // ─────────────────────────────────────
    // Dependencies (Phase 2)
    // ─────────────────────────────────────

    @Test
    fun `update blockedByTaskIds`() = runBlocking {
        createTestTask()
        createTestTask(id = "task-2", title = "Blocking Task")

        val result = useCase(
            taskId = testTaskId,
            blockedByTaskIds = listOf("task-2")
        )

        assertTrue(result.isSuccess)
        assertEquals(listOf("task-2"), result.getOrNull()!!.blockedByTaskIds)
    }

    @Test
    fun `self-reference in blockedByTaskIds returns CircularDependencyError`() = runBlocking {
        createTestTask()

        val result = useCase(
            taskId = testTaskId,
            blockedByTaskIds = listOf(testTaskId) // self-reference
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.CircularDependencyError)
    }

    // ─────────────────────────────────────
    // Partial Update
    // ─────────────────────────────────────

    @Test
    fun `update priority keeps other fields unchanged`() = runBlocking {
        val task = Task(
            id = testTaskId,
            projectId = testProjectId,
            title = "Original Title",
            priority = Priority.P4,
            workflowState = WorkflowState.TODO,
            note = "Original Note",
            sectionId = "section-1",
            tagIds = listOf("tag1"),
            createdAt = testNowMillis
        )
        taskRepository.addTask(task)

        val result = useCase(
            taskId = testTaskId,
            priority = Priority.P1
        )

        assertTrue(result.isSuccess)
        val updated = result.getOrNull()!!
        assertEquals(Priority.P1, updated.priority) // changed
        assertEquals("Original Title", updated.title) // unchanged
        assertEquals(WorkflowState.TODO, updated.workflowState) // unchanged
        assertEquals("Original Note", updated.note) // unchanged
        assertEquals("section-1", updated.sectionId) // unchanged
        assertEquals(listOf("tag1"), updated.tagIds) // unchanged
    }

    // ─────────────────────────────────────
    // Error Cases
    // ─────────────────────────────────────

    @Test
    fun `update non-existent task returns NotFoundError`() = runBlocking {
        val result = useCase(
            taskId = "non-existent",
            title = "New Title"
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.NotFoundError)
    }

    @Test
    fun `update with empty title returns EmptyTitleError`() = runBlocking {
        createTestTask()

        val result = useCase(
            taskId = testTaskId,
            title = ""
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.EmptyTitleError)
    }

    @Test
    fun `update with whitespace title returns EmptyTitleError`() = runBlocking {
        createTestTask()

        val result = useCase(
            taskId = testTaskId,
            title = "   "
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.EmptyTitleError)
    }

    // ─────────────────────────────────────
    // Persistence
    // ─────────────────────────────────────

    @Test
    fun `updated task is saved to repository`() = runBlocking {
        createTestTask()

        useCase(taskId = testTaskId, title = "Updated Title")

        val savedTask = taskRepository.getTaskById(testTaskId)
        assertNotNull(savedTask)
        assertEquals("Updated Title", savedTask!!.title)
    }

    @Test
    fun `updatedAt is changed on update`() = runBlocking {
        val task = createTestTask()
        val originalUpdatedAt = task.updatedAt

        Thread.sleep(10) // ensure time difference

        val result = useCase(taskId = testTaskId, title = "New Title")

        assertTrue(result.isSuccess)
        assertTrue(result.getOrNull()!!.updatedAt > originalUpdatedAt)
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
