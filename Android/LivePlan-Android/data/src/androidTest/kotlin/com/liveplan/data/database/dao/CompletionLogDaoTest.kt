package com.liveplan.data.database.dao

import android.database.sqlite.SQLiteConstraintException
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.Priority
import com.liveplan.core.model.ProjectStatus
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.WorkflowState
import com.liveplan.data.database.AppDatabase
import com.liveplan.data.database.entity.CompletionLogEntity
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
 * Room DAO tests for CompletionLogDao
 *
 * Critical tests for (taskId, occurrenceKey) unique constraint
 */
@RunWith(AndroidJUnit4::class)
class CompletionLogDaoTest {

    private lateinit var database: AppDatabase
    private lateinit var completionLogDao: CompletionLogDao
    private lateinit var taskDao: TaskDao
    private lateinit var projectDao: ProjectDao

    private val testProjectId = "project-1"
    private val testTaskId = "task-1"

    @Before
    fun setUp() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).allowMainThreadQueries().build()
        completionLogDao = database.completionLogDao()
        taskDao = database.taskDao()
        projectDao = database.projectDao()

        // Create parent project and task for foreign key constraints
        runBlocking {
            projectDao.insert(createProject(testProjectId))
            taskDao.insert(createTask(testTaskId))
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
    fun insertAndGetByTaskAndOccurrenceKey() = runBlocking {
        val log = createLog("log-1", testTaskId, "2026-02-03")
        completionLogDao.insert(log)

        val loaded = completionLogDao.getByTaskAndOccurrenceKey(testTaskId, "2026-02-03")

        assertNotNull(loaded)
        assertEquals("log-1", loaded?.id)
        assertEquals("2026-02-03", loaded?.occurrenceKey)
    }

    @Test
    fun getLogsByTask() = runBlocking {
        val log1 = createLog("log-1", testTaskId, "2026-02-01")
        val log2 = createLog("log-2", testTaskId, "2026-02-02")
        completionLogDao.insert(log1)
        completionLogDao.insert(log2)

        val logs = completionLogDao.getLogsByTask(testTaskId).first()

        assertEquals(2, logs.size)
    }

    // ─────────────────────────────────────
    // Unique Constraint Tests (CRITICAL)
    // ─────────────────────────────────────

    @Test
    fun uniqueConstraintEnforced() = runBlocking {
        val log1 = createLog("log-1", testTaskId, "2026-02-03")
        completionLogDao.insert(log1)

        // Try to insert another log with same taskId + occurrenceKey
        val log2 = createLog("log-2", testTaskId, "2026-02-03")

        try {
            completionLogDao.insert(log2)
            fail("Expected SQLiteConstraintException due to unique constraint")
        } catch (e: SQLiteConstraintException) {
            // Expected
        }
    }

    @Test
    fun differentOccurrenceKeysSameTaskAllowed() = runBlocking {
        val log1 = createLog("log-1", testTaskId, "2026-02-01")
        val log2 = createLog("log-2", testTaskId, "2026-02-02")
        completionLogDao.insert(log1)
        completionLogDao.insert(log2)

        val logs = completionLogDao.getLogsByTask(testTaskId).first()
        assertEquals(2, logs.size)
    }

    @Test
    fun sameOccurrenceKeyDifferentTasksAllowed() = runBlocking {
        // Create second task
        taskDao.insert(createTask("task-2"))

        val log1 = createLog("log-1", testTaskId, "2026-02-03")
        val log2 = createLog("log-2", "task-2", "2026-02-03")
        completionLogDao.insert(log1)
        completionLogDao.insert(log2)

        val task1Logs = completionLogDao.getLogsByTask(testTaskId).first()
        val task2Logs = completionLogDao.getLogsByTask("task-2").first()

        assertEquals(1, task1Logs.size)
        assertEquals(1, task2Logs.size)
    }

    // ─────────────────────────────────────
    // oneOff Completion (ONCE_KEY)
    // ─────────────────────────────────────

    @Test
    fun oneOffCompletionWithOnceKey() = runBlocking {
        val log = createLog("log-1", testTaskId, CompletionLog.ONCE_KEY)
        completionLogDao.insert(log)

        val loaded = completionLogDao.getByTaskAndOccurrenceKey(testTaskId, CompletionLog.ONCE_KEY)

        assertNotNull(loaded)
        assertEquals(CompletionLog.ONCE_KEY, loaded?.occurrenceKey)
    }

    @Test
    fun oneOffDuplicateRejected() = runBlocking {
        val log1 = createLog("log-1", testTaskId, CompletionLog.ONCE_KEY)
        completionLogDao.insert(log1)

        val log2 = createLog("log-2", testTaskId, CompletionLog.ONCE_KEY)

        try {
            completionLogDao.insert(log2)
            fail("Expected SQLiteConstraintException for duplicate oneOff completion")
        } catch (e: SQLiteConstraintException) {
            // Expected
        }
    }

    // ─────────────────────────────────────
    // hasCompletion Query
    // ─────────────────────────────────────

    @Test
    fun hasCompletionReturnsTrueWhenExists() = runBlocking {
        val log = createLog("log-1", testTaskId, "2026-02-03")
        completionLogDao.insert(log)

        val exists = completionLogDao.hasCompletion(testTaskId, "2026-02-03")

        assertTrue(exists)
    }

    @Test
    fun hasCompletionReturnsFalseWhenNotExists() = runBlocking {
        val exists = completionLogDao.hasCompletion(testTaskId, "2026-02-03")

        assertFalse(exists)
    }

    // ─────────────────────────────────────
    // Cascade Delete (Task → CompletionLog)
    // ─────────────────────────────────────

    @Test
    fun cascadeDeleteOnTaskRemoval() = runBlocking {
        val log = createLog("log-1", testTaskId, "2026-02-03")
        completionLogDao.insert(log)

        // Delete parent task
        taskDao.deleteById(testTaskId)

        // Log should be deleted via cascade
        val logs = completionLogDao.getAllLogs().first()
        assertTrue(logs.isEmpty())
    }

    // ─────────────────────────────────────
    // Delete Tests
    // ─────────────────────────────────────

    @Test
    fun deleteById() = runBlocking {
        val log = createLog("log-1", testTaskId, "2026-02-03")
        completionLogDao.insert(log)

        completionLogDao.deleteById("log-1")

        val loaded = completionLogDao.getByTaskAndOccurrenceKey(testTaskId, "2026-02-03")
        assertNull(loaded)
    }

    @Test
    fun deleteByTask() = runBlocking {
        val log1 = createLog("log-1", testTaskId, "2026-02-01")
        val log2 = createLog("log-2", testTaskId, "2026-02-02")
        completionLogDao.insert(log1)
        completionLogDao.insert(log2)

        completionLogDao.deleteByTaskId(testTaskId)

        val logs = completionLogDao.getLogsByTask(testTaskId).first()
        assertTrue(logs.isEmpty())
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

    private fun createTask(id: String): TaskEntity {
        val now = System.currentTimeMillis()
        return TaskEntity(
            id = id,
            projectId = testProjectId,
            title = "Test Task",
            sectionId = null,
            tagIdsJson = Json.encodeToString(emptyList<String>()),
            priority = Priority.P4.name,
            workflowState = WorkflowState.TODO.name,
            startAt = null,
            dueAt = null,
            note = null,
            recurrenceRuleJson = null,
            recurrenceBehavior = RecurrenceBehavior.HABIT_RESET.name,
            nextOccurrenceDueAt = null,
            blockedByTaskIdsJson = Json.encodeToString(emptyList<String>()),
            createdAt = now,
            updatedAt = now
        )
    }

    private fun createLog(id: String, taskId: String, occurrenceKey: String): CompletionLogEntity {
        return CompletionLogEntity(
            id = id,
            taskId = taskId,
            completedAt = System.currentTimeMillis(),
            occurrenceKey = occurrenceKey
        )
    }
}
