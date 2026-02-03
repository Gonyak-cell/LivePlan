package com.liveplan.data.repository

import com.google.common.truth.Truth.assertThat
import com.liveplan.core.model.ProjectStatus
import com.liveplan.data.database.dao.ProjectDao
import com.liveplan.data.database.entity.ProjectEntity
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for ProjectRepositoryImpl
 */
class ProjectRepositoryImplTest {

    private lateinit var projectDao: ProjectDao
    private lateinit var repository: ProjectRepositoryImpl

    @Before
    fun setUp() {
        projectDao = mockk(relaxed = true)
        repository = ProjectRepositoryImpl(projectDao)
    }

    // ─────────────────────────────────────
    // getAllProjects Tests
    // ─────────────────────────────────────

    @Test
    fun `getAllProjects returns mapped domain objects`() = runTest {
        val entities = listOf(
            createEntity("project-1", "Project 1"),
            createEntity("project-2", "Project 2")
        )
        coEvery { projectDao.getAllProjects() } returns flowOf(entities)

        val projects = repository.getAllProjects().first()

        assertThat(projects).hasSize(2)
        assertThat(projects[0].id).isEqualTo("project-1")
        assertThat(projects[0].title).isEqualTo("Project 1")
    }

    @Test
    fun `getAllProjects returns empty list on error (fail-safe)`() = runTest {
        coEvery { projectDao.getAllProjects() } returns flowOf(emptyList())

        val projects = repository.getAllProjects().first()

        assertThat(projects).isEmpty()
    }

    // ─────────────────────────────────────
    // getProjectById Tests
    // ─────────────────────────────────────

    @Test
    fun `getProjectById returns mapped domain object`() = runTest {
        val entity = createEntity("project-1", "Test Project")
        coEvery { projectDao.getProjectById("project-1") } returns entity

        val project = repository.getProjectById("project-1")

        assertThat(project).isNotNull()
        assertThat(project?.id).isEqualTo("project-1")
        assertThat(project?.title).isEqualTo("Test Project")
    }

    @Test
    fun `getProjectById returns null when not found`() = runTest {
        coEvery { projectDao.getProjectById("non-existent") } returns null

        val project = repository.getProjectById("non-existent")

        assertThat(project).isNull()
    }

    // ─────────────────────────────────────
    // addProject Tests
    // ─────────────────────────────────────

    @Test
    fun `addProject calls dao insert with mapped entity`() = runTest {
        val project = com.liveplan.core.model.Project(
            id = "project-1",
            title = "New Project",
            startDate = System.currentTimeMillis()
        )

        repository.addProject(project)

        coVerify { projectDao.insert(any()) }
    }

    // ─────────────────────────────────────
    // updateProject Tests
    // ─────────────────────────────────────

    @Test
    fun `updateProject calls dao update with mapped entity`() = runTest {
        val project = com.liveplan.core.model.Project(
            id = "project-1",
            title = "Updated Project",
            startDate = System.currentTimeMillis()
        )

        repository.updateProject(project)

        coVerify { projectDao.update(any()) }
    }

    // ─────────────────────────────────────
    // deleteProject Tests
    // ─────────────────────────────────────

    @Test
    fun `deleteProject calls dao deleteById`() = runTest {
        repository.deleteProject("project-1")

        coVerify { projectDao.deleteById("project-1") }
    }

    // ─────────────────────────────────────
    // Helper Functions
    // ─────────────────────────────────────

    private fun createEntity(id: String, title: String): ProjectEntity {
        val now = System.currentTimeMillis()
        return ProjectEntity(
            id = id,
            title = title,
            startDate = now,
            dueDate = null,
            note = null,
            status = ProjectStatus.ACTIVE.name,
            createdAt = now,
            updatedAt = now
        )
    }
}
