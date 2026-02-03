package com.liveplan.data.database.dao

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.liveplan.core.model.ProjectStatus
import com.liveplan.data.database.AppDatabase
import com.liveplan.data.database.entity.ProjectEntity
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Room DAO tests for ProjectDao using In-Memory database
 */
@RunWith(AndroidJUnit4::class)
class ProjectDaoTest {

    private lateinit var database: AppDatabase
    private lateinit var projectDao: ProjectDao

    @Before
    fun setUp() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).allowMainThreadQueries().build()
        projectDao = database.projectDao()
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
        val project = createProject("project-1", "Test Project")
        projectDao.insert(project)

        val loaded = projectDao.getProjectById("project-1")

        assertNotNull(loaded)
        assertEquals("project-1", loaded?.id)
        assertEquals("Test Project", loaded?.title)
    }

    @Test
    fun insertAndGetAll() = runBlocking {
        val project1 = createProject("project-1", "Project 1")
        val project2 = createProject("project-2", "Project 2")
        projectDao.insert(project1)
        projectDao.insert(project2)

        val allProjects = projectDao.getAllProjects().first()

        assertEquals(2, allProjects.size)
    }

    // ─────────────────────────────────────
    // Update Tests
    // ─────────────────────────────────────

    @Test
    fun updateProject() = runBlocking {
        val project = createProject("project-1", "Original Title")
        projectDao.insert(project)

        val updated = project.copy(title = "Updated Title")
        projectDao.update(updated)

        val loaded = projectDao.getProjectById("project-1")
        assertEquals("Updated Title", loaded?.title)
    }

    // ─────────────────────────────────────
    // Delete Tests
    // ─────────────────────────────────────

    @Test
    fun deleteById() = runBlocking {
        val project = createProject("project-1", "Test Project")
        projectDao.insert(project)

        projectDao.deleteById("project-1")

        val loaded = projectDao.getProjectById("project-1")
        assertNull(loaded)
    }

    // ─────────────────────────────────────
    // Active Projects Filter
    // ─────────────────────────────────────

    @Test
    fun getActiveProjectsExcludesArchived() = runBlocking {
        val activeProject = createProject("project-1", "Active", ProjectStatus.ACTIVE)
        val archivedProject = createProject("project-2", "Archived", ProjectStatus.ARCHIVED)
        projectDao.insert(activeProject)
        projectDao.insert(archivedProject)

        val activeProjects = projectDao.getActiveProjects().first()

        assertEquals(1, activeProjects.size)
        assertEquals("project-1", activeProjects[0].id)
    }

    // ─────────────────────────────────────
    // Round-trip Test
    // ─────────────────────────────────────

    @Test
    fun roundTripAllFields() = runBlocking {
        val now = System.currentTimeMillis()
        val project = ProjectEntity(
            id = "project-1",
            title = "Full Project",
            startDate = now,
            dueDate = now + 7 * 24 * 60 * 60 * 1000L, // 7 days later
            note = "This is a note",
            status = ProjectStatus.ACTIVE.name,
            createdAt = now,
            updatedAt = now
        )
        projectDao.insert(project)

        val loaded = projectDao.getProjectById("project-1")

        assertNotNull(loaded)
        assertEquals(project.id, loaded?.id)
        assertEquals(project.title, loaded?.title)
        assertEquals(project.startDate, loaded?.startDate)
        assertEquals(project.dueDate, loaded?.dueDate)
        assertEquals(project.note, loaded?.note)
        assertEquals(project.status, loaded?.status)
        assertEquals(project.createdAt, loaded?.createdAt)
        assertEquals(project.updatedAt, loaded?.updatedAt)
    }

    // ─────────────────────────────────────
    // Helper Functions
    // ─────────────────────────────────────

    private fun createProject(
        id: String,
        title: String,
        status: ProjectStatus = ProjectStatus.ACTIVE
    ): ProjectEntity {
        val now = System.currentTimeMillis()
        return ProjectEntity(
            id = id,
            title = title,
            startDate = now,
            dueDate = null,
            note = null,
            status = status.name,
            createdAt = now,
            updatedAt = now
        )
    }
}
