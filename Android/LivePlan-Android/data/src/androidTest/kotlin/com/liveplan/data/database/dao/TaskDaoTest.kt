package com.liveplan.data.database.dao

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.liveplan.core.model.Priority
import com.liveplan.core.model.ProjectStatus
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.WorkflowState
import com.liveplan.data.database.AppDatabase
import com.liveplan.data.database.entity.ProjectEntity
import com.liveplan.data.database.entity.TaskEntity
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Room DAO tests for TaskDao using In-Memory database
 */
@RunWith(AndroidJUnit4::class)
class TaskDaoTest {

    private lateinit var database: AppDatabase
    private lateinit var taskDao: TaskDao
    private lateinit var projectDao: ProjectDao

    private val testProjectId = "project-1"

    @Before
    fun setUp() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).allowMainThreadQueries().build()
        taskDao = database.taskDao()
        projectDao = database.projectDao()

        // Create parent project for foreign key constraint
        runBlocking {
            projectDao.insert(createProject(testProjectId))
        }
    }

    @After
    fun tearDown() {
        database.close()
    }

    // ─────────────────────────────────────
    // Insert / Get Tests
    // ─────────────────────────────────────

    @Test
    fun insertAndGetById() = runBlocking {
        val task = createTask("task-1", "Test Task")
        taskDao.insert(task)

        val loaded = taskDao.getTaskById("task-1")

        assertNotNull(loaded)
        assertEquals("task-1", loaded?.id)
        assertEquals("Test Task", loaded?.title)
    }

    @Test
    fun getTasksByProject() = runBlocking {
        val task1 = createTask("task-1", "Task 1")
        val task2 = createTask("task-2", "Task 2")
        taskDao.insert(task1)
        taskDao.insert(task2)

        val tasks = taskDao.getTasksByProject(testProjectId).first()

        assertEquals(2, tasks.size)
    }

    // ─────────────────────────────────────
    // Update Tests
    // ─────────────────────────────────────

    @Test
    fun updateTask() = runBlocking {
        val task = createTask("task-1", "Original Title")
        taskDao.insert(task)

        val updated = task.copy(title = "Updated Title")
        taskDao.update(updated)

        val loaded = taskDao.getTaskById("task-1")
        assertEquals("Updated Title", loaded?.title)
    }

    // ─────────────────────────────────────
    // Delete Tests
    // ─────────────────────────────────────

    @Test
    fun deleteById() = runBlocking {
        val task = createTask("task-1", "Test Task")
        taskDao.insert(task)

        taskDao.deleteById("task-1")

        val loaded = taskDao.getTaskById("task-1")
        assertNull(loaded)
    }

    // ─────────────────────────────────────
    // Cascade Delete (Project → Task)
    // ─────────────────────────────────────

    @Test
    fun cascadeDeleteOnProjectRemoval() = runBlocking {
        val task = createTask("task-1", "Test Task")
        taskDao.insert(task)

        // Delete parent project
        projectDao.deleteById(testProjectId)

        // Task should be deleted via cascade
        val loaded = taskDao.getTaskById("task-1")
        assertNull(loaded)
    }

    // ─────────────────────────────────────
    // Priority / WorkflowState Fields
    // ─────────────────────────────────────

    @Test
    fun priorityFieldPersistence() = runBlocking {
        val task = createTask("task-1", "P1 Task", priority = Priority.P1)
        taskDao.insert(task)

        val loaded = taskDao.getTaskById("task-1")
        assertEquals(Priority.P1.name, loaded?.priority)
    }

    @Test
    fun workflowStateFieldPersistence() = runBlocking {
        val task = createTask("task-1", "Doing Task", workflowState = WorkflowState.DOING)
        taskDao.insert(task)

        val loaded = taskDao.getTaskById("task-1")
        assertEquals(WorkflowState.DOING.name, loaded?.workflowState)
    }

    // ─────────────────────────────────────
    // JSON Fields (tagIds, blockedByTaskIds)
    // ─────────────────────────────────────

    @Test
    fun tagIdsJsonRoundTrip() = runBlocking {
        val tagIds = listOf("tag-1", "tag-2", "tag-3")
        val task = createTask("task-1", "Tagged Task", tagIds = tagIds)
        taskDao.insert(task)

        val loaded = taskDao.getTaskById("task-1")
        val loadedTagIds: List<String> = Json.decodeFromString(loaded!!.tagIdsJson)
        assertEquals(tagIds, loadedTagIds)
    }

    @Test
    fun blockedByTaskIdsJsonRoundTrip() = runBlocking {
        // First, create another task to block
        val blockerTask = createTask("blocker-1", "Blocker Task")
        taskDao.insert(blockerTask)

        val blockedByIds = listOf("blocker-1")
        val task = createTask("task-1", "Blocked Task", blockedByTaskIds = blockedByIds)
        taskDao.insert(task)

        val loaded = taskDao.getTaskById("task-1")
        val loadedBlockedIds: List<String> = Json.decodeFromString(loaded!!.blockedByTaskIdsJson)
        assertEquals(blockedByIds, loadedBlockedIds)
    }

    // ─────────────────────────────────────
    // Round-trip All Fields
    // ─────────────────────────────────────

    @Test
    fun roundTripAllFields() = runBlocking {
        val now = System.currentTimeMillis()
        val task = TaskEntity(
            id = "task-full",
            projectId = testProjectId,
            title = "Full Task",
            sectionId = null,
            tagIdsJson = Json.encodeToString(listOf("tag-1")),
            priority = Priority.P2.name,
            workflowState = WorkflowState.TODO.name,
            startAt = now,
            dueAt = now + 86400000L,
            note = "Task note",
            recurrenceRuleJson = null,
            recurrenceBehavior = RecurrenceBehavior.HABIT_RESET.name,
            nextOccurrenceDueAt = null,
            blockedByTaskIdsJson = Json.encodeToString(emptyList<String>()),
            createdAt = now,
            updatedAt = now
        )
        taskDao.insert(task)

        val loaded = taskDao.getTaskById("task-full")

        assertNotNull(loaded)
        assertEquals(task.id, loaded?.id)
        assertEquals(task.projectId, loaded?.projectId)
        assertEquals(task.title, loaded?.title)
        assertEquals(task.sectionId, loaded?.sectionId)
        assertEquals(task.tagIdsJson, loaded?.tagIdsJson)
        assertEquals(task.priority, loaded?.priority)
        assertEquals(task.workflowState, loaded?.workflowState)
        assertEquals(task.startAt, loaded?.startAt)
        assertEquals(task.dueAt, loaded?.dueAt)
        assertEquals(task.note, loaded?.note)
        assertEquals(task.recurrenceRuleJson, loaded?.recurrenceRuleJson)
        assertEquals(task.recurrenceBehavior, loaded?.recurrenceBehavior)
        assertEquals(task.nextOccurrenceDueAt, loaded?.nextOccurrenceDueAt)
        assertEquals(task.blockedByTaskIdsJson, loaded?.blockedByTaskIdsJson)
        assertEquals(task.createdAt, loaded?.createdAt)
        assertEquals(task.updatedAt, loaded?.updatedAt)
    }

    // ─────────────────────────────────────
    // Helper Functions
    // ─────────────────────────────────────

    private fun createProject(id: String): ProjectEntity {
        val now = System.currentTimeMillis()
        return ProjectEntity(
            id = id,
            title = "Test Project",
            startDate = now,
            dueDate = null,
            note = null,
            status = ProjectStatus.ACTIVE.name,
            createdAt = now,
            updatedAt = now
        )
    }

    private fun createTask(
        id: String,
        title: String,
        priority: Priority = Priority.P4,
        workflowState: WorkflowState = WorkflowState.TODO,
        tagIds: List<String> = emptyList(),
        blockedByTaskIds: List<String> = emptyList()
    ): TaskEntity {
        val now = System.currentTimeMillis()
        return TaskEntity(
            id = id,
            projectId = testProjectId,
            title = title,
            sectionId = null,
            tagIdsJson = Json.encodeToString(tagIds),
            priority = priority.name,
            workflowState = workflowState.name,
            startAt = null,
            dueAt = null,
            note = null,
            recurrenceRuleJson = null,
            recurrenceBehavior = RecurrenceBehavior.HABIT_RESET.name,
            nextOccurrenceDueAt = null,
            blockedByTaskIdsJson = Json.encodeToString(blockedByTaskIds),
            createdAt = now,
            updatedAt = now
        )
    }
}
