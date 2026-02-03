package com.liveplan.data.database.dao

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.liveplan.core.model.ProjectStatus
import com.liveplan.data.database.AppDatabase
import com.liveplan.data.database.entity.ProjectEntity
import com.liveplan.data.database.entity.SectionEntity
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Room DAO tests for SectionDao
 */
@RunWith(AndroidJUnit4::class)
class SectionDaoTest {

    private lateinit var database: AppDatabase
    private lateinit var sectionDao: SectionDao
    private lateinit var projectDao: ProjectDao

    private val testProjectId = "project-1"

    @Before
    fun setUp() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).allowMainThreadQueries().build()
        sectionDao = database.sectionDao()
        projectDao = database.projectDao()

        // Create parent project
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
        val section = createSection("section-1", "To Do", 0)
        sectionDao.insert(section)

        val loaded = sectionDao.getSectionById("section-1")

        assertNotNull(loaded)
        assertEquals("section-1", loaded?.id)
        assertEquals("To Do", loaded?.title)
        assertEquals(0, loaded?.orderIndex)
    }

    @Test
    fun getSectionsByProject() = runBlocking {
        val section1 = createSection("section-1", "To Do", 0)
        val section2 = createSection("section-2", "In Progress", 1)
        val section3 = createSection("section-3", "Done", 2)
        sectionDao.insert(section1)
        sectionDao.insert(section2)
        sectionDao.insert(section3)

        val sections = sectionDao.getSectionsByProject(testProjectId).first()

        assertEquals(3, sections.size)
        // Verify ordering
        assertEquals("section-1", sections[0].id)
        assertEquals("section-2", sections[1].id)
        assertEquals("section-3", sections[2].id)
    }

    // ─────────────────────────────────────
    // Update Tests
    // ─────────────────────────────────────

    @Test
    fun updateSection() = runBlocking {
        val section = createSection("section-1", "To Do", 0)
        sectionDao.insert(section)

        val updated = section.copy(title = "Backlog", orderIndex = 5)
        sectionDao.update(updated)

        val loaded = sectionDao.getSectionById("section-1")
        assertEquals("Backlog", loaded?.title)
        assertEquals(5, loaded?.orderIndex)
    }

    // ─────────────────────────────────────
    // Delete Tests
    // ─────────────────────────────────────

    @Test
    fun deleteById() = runBlocking {
        val section = createSection("section-1", "To Do", 0)
        sectionDao.insert(section)

        sectionDao.deleteById("section-1")

        val loaded = sectionDao.getSectionById("section-1")
        assertNull(loaded)
    }

    // ─────────────────────────────────────
    // Cascade Delete (Project → Section)
    // ─────────────────────────────────────

    @Test
    fun cascadeDeleteOnProjectRemoval() = runBlocking {
        val section = createSection("section-1", "To Do", 0)
        sectionDao.insert(section)

        projectDao.deleteById(testProjectId)

        val loaded = sectionDao.getSectionById("section-1")
        assertNull(loaded)
    }

    // ─────────────────────────────────────
    // Order Index Tests
    // ─────────────────────────────────────

    @Test
    fun sectionsOrderedByOrderIndex() = runBlocking {
        // Insert in reverse order
        sectionDao.insert(createSection("section-3", "Done", 2))
        sectionDao.insert(createSection("section-1", "To Do", 0))
        sectionDao.insert(createSection("section-2", "In Progress", 1))

        val sections = sectionDao.getSectionsByProject(testProjectId).first()

        assertEquals(3, sections.size)
        assertEquals(0, sections[0].orderIndex)
        assertEquals(1, sections[1].orderIndex)
        assertEquals(2, sections[2].orderIndex)
    }

    // ─────────────────────────────────────
    // Round-trip Test
    // ─────────────────────────────────────

    @Test
    fun roundTripAllFields() = runBlocking {
        val section = SectionEntity(
            id = "section-full",
            projectId = testProjectId,
            title = "Full Section",
            orderIndex = 42
        )
        sectionDao.insert(section)

        val loaded = sectionDao.getSectionById("section-full")

        assertNotNull(loaded)
        assertEquals(section.id, loaded?.id)
        assertEquals(section.projectId, loaded?.projectId)
        assertEquals(section.title, loaded?.title)
        assertEquals(section.orderIndex, loaded?.orderIndex)
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

    private fun createSection(id: String, title: String, orderIndex: Int): SectionEntity {
        return SectionEntity(
            id = id,
            projectId = testProjectId,
            title = title,
            orderIndex = orderIndex
        )
    }
}
