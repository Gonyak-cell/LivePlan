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
 * Tests for AddProjectUseCase
 * - testing.md A1: AppCore unit tests required
 * - data-model.md A1: Project field validation
 */
class AddProjectUseCaseTest {

    private lateinit var projectRepository: FakeProjectRepository
    private lateinit var useCase: AddProjectUseCase

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
        useCase = AddProjectUseCase(projectRepository)
    }

    // ─────────────────────────────────────
    // Success Cases
    // ─────────────────────────────────────

    @Test
    fun `create basic project succeeds`() = runBlocking {
        val result = useCase(
            title = "New Project",
            startDate = testStartDate
        )

        assertTrue(result.isSuccess)
        val project = result.getOrNull()!!
        assertEquals("New Project", project.title)
        assertEquals(testStartDate, project.startDate)
        assertNull(project.dueDate)
        assertEquals(ProjectStatus.ACTIVE, project.status)
    }

    @Test
    fun `create project with dueDate succeeds`() = runBlocking {
        val result = useCase(
            title = "Project with Due Date",
            startDate = testStartDate,
            dueDate = testDueDate
        )

        assertTrue(result.isSuccess)
        val project = result.getOrNull()!!
        assertEquals(testDueDate, project.dueDate)
    }

    @Test
    fun `create project with dueDate equals startDate succeeds`() = runBlocking {
        val result = useCase(
            title = "Same Day Project",
            startDate = testStartDate,
            dueDate = testStartDate
        )

        assertTrue(result.isSuccess)
        val project = result.getOrNull()!!
        assertEquals(project.startDate, project.dueDate)
    }

    @Test
    fun `create project with note succeeds`() = runBlocking {
        val result = useCase(
            title = "Project with Note",
            startDate = testStartDate,
            note = "This is a project note"
        )

        assertTrue(result.isSuccess)
        val project = result.getOrNull()!!
        assertEquals("This is a project note", project.note)
    }

    @Test
    fun `title is trimmed`() = runBlocking {
        val result = useCase(
            title = "  Trimmed Title  ",
            startDate = testStartDate
        )

        assertTrue(result.isSuccess)
        assertEquals("Trimmed Title", result.getOrNull()!!.title)
    }

    // ─────────────────────────────────────
    // Error Cases
    // ─────────────────────────────────────

    @Test
    fun `empty title returns EmptyTitleError`() = runBlocking {
        val result = useCase(
            title = "",
            startDate = testStartDate
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.EmptyTitleError)
    }

    @Test
    fun `whitespace only title returns EmptyTitleError`() = runBlocking {
        val result = useCase(
            title = "   ",
            startDate = testStartDate
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.EmptyTitleError)
    }

    @Test
    fun `dueDate before startDate returns ValidationError`() = runBlocking {
        val invalidDueDate = testStartDate - 24 * 60 * 60 * 1000L // 1 day before

        val result = useCase(
            title = "Invalid Project",
            startDate = testStartDate,
            dueDate = invalidDueDate
        )

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.ValidationError)
    }

    // ─────────────────────────────────────
    // Persistence
    // ─────────────────────────────────────

    @Test
    fun `created project is saved to repository`() = runBlocking {
        val result = useCase(
            title = "Saved Project",
            startDate = testStartDate
        )

        assertTrue(result.isSuccess)
        val project = result.getOrNull()!!

        val savedProject = projectRepository.getProjectById(project.id)
        assertNotNull(savedProject)
        assertEquals("Saved Project", savedProject!!.title)
    }

    @Test
    fun `multiple projects can be created`() = runBlocking {
        useCase(title = "Project 1", startDate = testStartDate)
        useCase(title = "Project 2", startDate = testStartDate)
        useCase(title = "Project 3", startDate = testStartDate)

        assertEquals(3, projectRepository.projects.size)
    }

    // ─────────────────────────────────────
    // Fake Repository
    // ─────────────────────────────────────

    private class FakeProjectRepository : ProjectRepository {
        val projects = mutableMapOf<String, Project>()
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
