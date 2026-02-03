package com.liveplan.core.usecase

import com.liveplan.core.error.AppError
import com.liveplan.core.model.Project
import com.liveplan.core.model.ProjectStatus
import com.liveplan.core.repository.ProjectRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/**
 * Tests for UpdateProjectUseCase
 * - testing.md A1: AppCore unit tests required
 * - data-model.md A1: Project update validation
 */
class UpdateProjectUseCaseTest {

    private lateinit var projectRepository: FakeProjectRepository
    private lateinit var useCase: UpdateProjectUseCase

    private val testProjectId = "project-1"
    private val testStartDate: Long
    private val testDueDate: Long

    init {
        val calendar = Calendar.getInstance(TimeZone.getDefault()).apply {
            set(2026, Calendar.FEBRUARY, 3, 10, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        testStartDate = calendar.timeInMillis
        testDueDate = testStartDate + 7 * 24 * 60 * 60 * 1000L // 7 days later
    }

    @Before
    fun setUp() {
        projectRepository = FakeProjectRepository()
        useCase = UpdateProjectUseCase(projectRepository)
    }

    private suspend fun createTestProject(
        id: String = testProjectId,
        title: String = "Test Project",
        startDate: Long = testStartDate,
        dueDate: Long? = testDueDate
    ): Project {
        val project = Project(
            id = id,
            title = title,
            startDate = startDate,
            dueDate = dueDate
        )
        projectRepository.addProject(project)
        return project
    }

    // ─────────────────────────────────────
    // Success Cases
    // ─────────────────────────────────────

    @Test
    fun `update title succeeds`() = runBlocking {
        createTestProject()

        val result = useCase(
            projectId = testProjectId,
            title = "Updated Title"
        )

        assertTrue(result.isSuccess)
        assertEquals("Updated Title", result.getOrNull()!!.title)
    }

    @Test
    fun `update title is trimmed`() = runBlocking {
        createTestProject()

        val result = useCase(
            projectId = testProjectId,
            title = "  Trimmed Title  "
        )

        assertTrue(result.isSuccess)
        assertEquals("Trimmed Title", result.getOrNull()!!.title)
    }

    @Test
    fun `update startDate succeeds`() = runBlocking {
        createTestProject(dueDate = null)
        val newStartDate = testStartDate + 24 * 60 * 60 * 1000L

        val result = useCase(
            projectId = testProjectId,
            startDate = newStartDate
        )

        assertTrue(result.isSuccess)
        assertEquals(newStartDate, result.getOrNull()!!.startDate)
    }

    @Test
    fun `update dueDate succeeds`() = runBlocking {
        createTestProject()
        val newDueDate = testDueDate + 7 * 24 * 60 * 60 * 1000L

        val result = useCase(
            projectId = testProjectId,
            dueDate = newDueDate
        )

        assertTrue(result.isSuccess)
        assertEquals(newDueDate, result.getOrNull()!!.dueDate)
    }

    @Test
    fun `clear dueDate succeeds`() = runBlocking {
        createTestProject(dueDate = testDueDate)

        val result = useCase(
            projectId = testProjectId,
            clearDueDate = true
        )

        assertTrue(result.isSuccess)
        assertNull(result.getOrNull()!!.dueDate)
    }

    @Test
    fun `update note succeeds`() = runBlocking {
        createTestProject()

        val result = useCase(
            projectId = testProjectId,
            note = "New note"
        )

        assertTrue(result.isSuccess)
        assertEquals("New note", result.getOrNull()!!.note)
    }

    @Test
    fun `clear note succeeds`() = runBlocking {
        val project = Project(
            id = testProjectId,
            title = "Test",
            startDate = testStartDate,
            note = "Old note"
        )
        projectRepository.addProject(project)

        val result = useCase(
            projectId = testProjectId,
            clearNote = true
        )

        assertTrue(result.isSuccess)
        assertNull(result.getOrNull()!!.note)
    }

    @Test
    fun `update status to archived`() = runBlocking {
        createTestProject()

        val result = useCase(
            projectId = testProjectId,
            status = ProjectStatus.ARCHIVED
        )

        assertTrue(result.isSuccess)
        assertEquals(ProjectStatus.ARCHIVED, result.getOrNull()!!.status)
    }

    @Test
    fun `update multiple fields at once`() = runBlocking {
        createTestProject()
        val newDueDate = testDueDate + 14 * 24 * 60 * 60 * 1000L

        val result = useCase(
            projectId = testProjectId,
            title = "New Title",
            dueDate = newDueDate,
            note = "New Note"
        )

        assertTrue(result.isSuccess)
        val updated = result.getOrNull()!!
        assertEquals("New Title", updated.title)
        assertEquals(newDueDate, updated.dueDate)
        assertEquals("New Note", updated.note)
    }

    // ─────────────────────────────────────
    // Partial Update (Unchanged Fields)
    // ─────────────────────────────────────

    @Test
    fun `update title keeps other fields unchanged`() = runBlocking {
        val project = Project(
            id = testProjectId,
            title = "Original Title",
            startDate = testStartDate,
            dueDate = testDueDate,
            note = "Original Note",
            status = ProjectStatus.ACTIVE
        )
        projectRepository.addProject(project)

        val result = useCase(
            projectId = testProjectId,
            title = "New Title"
        )

        assertTrue(result.isSuccess)
        val updated = result.getOrNull()!!
        assertEquals("New Title", updated.title)
        assertEquals(testStartDate, updated.startDate) // unchanged
        assertEquals(testDueDate, updated.dueDate) // unchanged
        assertEquals("Original Note", updated.note) // unchanged
        assertEquals(ProjectStatus.ACTIVE, updated.status) // unchanged
    }

    // ─────────────────────────────────────
    // Error Cases
    // ─────────────────────────────────────

    @Test
    fun `update non-existent project returns NotFoundError`() = runBlocking {
        val result = useCase(
            projectId = "non-existent",
            title = "New Title"
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.NotFoundError)
    }

    @Test
    fun `update with empty title returns EmptyTitleError`() = runBlocking {
        createTestProject()

        val result = useCase(
            projectId = testProjectId,
            title = ""
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.EmptyTitleError)
    }

    @Test
    fun `update with whitespace title returns EmptyTitleError`() = runBlocking {
        createTestProject()

        val result = useCase(
            projectId = testProjectId,
            title = "   "
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.EmptyTitleError)
    }

    @Test
    fun `update dueDate before startDate returns ValidationError`() = runBlocking {
        createTestProject()
        val invalidDueDate = testStartDate - 24 * 60 * 60 * 1000L

        val result = useCase(
            projectId = testProjectId,
            dueDate = invalidDueDate
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.ValidationError)
    }

    // ─────────────────────────────────────
    // Persistence
    // ─────────────────────────────────────

    @Test
    fun `updated project is saved to repository`() = runBlocking {
        createTestProject()

        useCase(projectId = testProjectId, title = "Updated Title")

        val savedProject = projectRepository.getProjectById(testProjectId)
        assertNotNull(savedProject)
        assertEquals("Updated Title", savedProject!!.title)
    }

    @Test
    fun `updatedAt is changed on update`() = runBlocking {
        val project = createTestProject()
        val originalUpdatedAt = project.updatedAt

        Thread.sleep(10) // ensure time difference

        val result = useCase(projectId = testProjectId, title = "New Title")

        assertTrue(result.isSuccess)
        assertTrue(result.getOrNull()!!.updatedAt > originalUpdatedAt)
    }

    // ─────────────────────────────────────
    // Fake Repository
    // ─────────────────────────────────────

    private class FakeProjectRepository : ProjectRepository {
        private val projects = mutableMapOf<String, Project>()
        private val _flow = MutableStateFlow<List<Project>>(emptyList())

        override fun getAllProjects(): Flow<List<Project>> = _flow

        override fun getActiveProjects(): Flow<List<Project>> {
            return MutableStateFlow(projects.values.filter { it.isActive })
        }

        override suspend fun getProjectById(id: String): Project? = projects[id]

        override suspend fun addProject(project: Project) {
            projects[project.id] = project
            _flow.value = projects.values.toList()
        }

        override suspend fun updateProject(project: Project) {
            projects[project.id] = project
            _flow.value = projects.values.toList()
        }

        override suspend fun deleteProject(id: String) {
            projects.remove(id)
            _flow.value = projects.values.toList()
        }
    }
}
