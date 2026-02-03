package com.liveplan.data.di

import com.google.common.truth.Truth.assertThat
import com.liveplan.data.database.AppDatabase
import com.liveplan.data.database.dao.CompletionLogDao
import com.liveplan.data.database.dao.ProjectDao
import com.liveplan.data.database.dao.SectionDao
import com.liveplan.data.database.dao.TagDao
import com.liveplan.data.database.dao.TaskDao
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for DatabaseModule
 *
 * Tests verify that each DAO provider returns the correct DAO from the database.
 * Database creation is tested separately in instrumented tests since it requires
 * Android Context.
 *
 * Tests cover:
 * - ProjectDao provider
 * - TaskDao provider
 * - CompletionLogDao provider
 * - SectionDao provider
 * - TagDao provider
 */
class DatabaseModuleTest {

    private lateinit var mockDatabase: AppDatabase
    private lateinit var mockProjectDao: ProjectDao
    private lateinit var mockTaskDao: TaskDao
    private lateinit var mockCompletionLogDao: CompletionLogDao
    private lateinit var mockSectionDao: SectionDao
    private lateinit var mockTagDao: TagDao

    @Before
    fun setUp() {
        // Create mock DAOs
        mockProjectDao = mockk()
        mockTaskDao = mockk()
        mockCompletionLogDao = mockk()
        mockSectionDao = mockk()
        mockTagDao = mockk()

        // Create mock database that returns mock DAOs
        mockDatabase = mockk {
            every { projectDao() } returns mockProjectDao
            every { taskDao() } returns mockTaskDao
            every { completionLogDao() } returns mockCompletionLogDao
            every { sectionDao() } returns mockSectionDao
            every { tagDao() } returns mockTagDao
        }
    }

    // ─────────────────────────────────────
    // ProjectDao Provider Tests
    // ─────────────────────────────────────

    @Test
    fun `provideProjectDao returns ProjectDao from database`() {
        val result = DatabaseModule.provideProjectDao(mockDatabase)

        assertThat(result).isEqualTo(mockProjectDao)
        verify(exactly = 1) { mockDatabase.projectDao() }
    }

    @Test
    fun `provideProjectDao returns same instance on multiple calls`() {
        val result1 = DatabaseModule.provideProjectDao(mockDatabase)
        val result2 = DatabaseModule.provideProjectDao(mockDatabase)

        assertThat(result1).isEqualTo(result2)
    }

    // ─────────────────────────────────────
    // TaskDao Provider Tests
    // ─────────────────────────────────────

    @Test
    fun `provideTaskDao returns TaskDao from database`() {
        val result = DatabaseModule.provideTaskDao(mockDatabase)

        assertThat(result).isEqualTo(mockTaskDao)
        verify(exactly = 1) { mockDatabase.taskDao() }
    }

    @Test
    fun `provideTaskDao returns same instance on multiple calls`() {
        val result1 = DatabaseModule.provideTaskDao(mockDatabase)
        val result2 = DatabaseModule.provideTaskDao(mockDatabase)

        assertThat(result1).isEqualTo(result2)
    }

    // ─────────────────────────────────────
    // CompletionLogDao Provider Tests
    // ─────────────────────────────────────

    @Test
    fun `provideCompletionLogDao returns CompletionLogDao from database`() {
        val result = DatabaseModule.provideCompletionLogDao(mockDatabase)

        assertThat(result).isEqualTo(mockCompletionLogDao)
        verify(exactly = 1) { mockDatabase.completionLogDao() }
    }

    @Test
    fun `provideCompletionLogDao returns same instance on multiple calls`() {
        val result1 = DatabaseModule.provideCompletionLogDao(mockDatabase)
        val result2 = DatabaseModule.provideCompletionLogDao(mockDatabase)

        assertThat(result1).isEqualTo(result2)
    }

    // ─────────────────────────────────────
    // SectionDao Provider Tests
    // ─────────────────────────────────────

    @Test
    fun `provideSectionDao returns SectionDao from database`() {
        val result = DatabaseModule.provideSectionDao(mockDatabase)

        assertThat(result).isEqualTo(mockSectionDao)
        verify(exactly = 1) { mockDatabase.sectionDao() }
    }

    @Test
    fun `provideSectionDao returns same instance on multiple calls`() {
        val result1 = DatabaseModule.provideSectionDao(mockDatabase)
        val result2 = DatabaseModule.provideSectionDao(mockDatabase)

        assertThat(result1).isEqualTo(result2)
    }

    // ─────────────────────────────────────
    // TagDao Provider Tests
    // ─────────────────────────────────────

    @Test
    fun `provideTagDao returns TagDao from database`() {
        val result = DatabaseModule.provideTagDao(mockDatabase)

        assertThat(result).isEqualTo(mockTagDao)
        verify(exactly = 1) { mockDatabase.tagDao() }
    }

    @Test
    fun `provideTagDao returns same instance on multiple calls`() {
        val result1 = DatabaseModule.provideTagDao(mockDatabase)
        val result2 = DatabaseModule.provideTagDao(mockDatabase)

        assertThat(result1).isEqualTo(result2)
    }

    // ─────────────────────────────────────
    // All DAOs Integration Test
    // ─────────────────────────────────────

    @Test
    fun `all DAO providers return distinct DAOs`() {
        val projectDao = DatabaseModule.provideProjectDao(mockDatabase)
        val taskDao = DatabaseModule.provideTaskDao(mockDatabase)
        val completionLogDao = DatabaseModule.provideCompletionLogDao(mockDatabase)
        val sectionDao = DatabaseModule.provideSectionDao(mockDatabase)
        val tagDao = DatabaseModule.provideTagDao(mockDatabase)

        // Verify all DAOs are distinct objects
        val daos = listOf(projectDao, taskDao, completionLogDao, sectionDao, tagDao)
        assertThat(daos.distinct().size).isEqualTo(5)
    }

    @Test
    fun `database methods are called exactly once per provider call`() {
        DatabaseModule.provideProjectDao(mockDatabase)
        DatabaseModule.provideTaskDao(mockDatabase)
        DatabaseModule.provideCompletionLogDao(mockDatabase)
        DatabaseModule.provideSectionDao(mockDatabase)
        DatabaseModule.provideTagDao(mockDatabase)

        verify(exactly = 1) { mockDatabase.projectDao() }
        verify(exactly = 1) { mockDatabase.taskDao() }
        verify(exactly = 1) { mockDatabase.completionLogDao() }
        verify(exactly = 1) { mockDatabase.sectionDao() }
        verify(exactly = 1) { mockDatabase.tagDao() }
    }
}
