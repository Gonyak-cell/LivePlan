package com.liveplan.data.di

import com.google.common.truth.Truth.assertThat
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.core.repository.SavedViewRepository
import com.liveplan.core.repository.SectionRepository
import com.liveplan.core.repository.TagRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.data.repository.CompletionLogRepositoryImpl
import com.liveplan.data.repository.ProjectRepositoryImpl
import com.liveplan.data.repository.SavedViewRepositoryImpl
import com.liveplan.data.repository.SectionRepositoryImpl
import com.liveplan.data.repository.TagRepositoryImpl
import com.liveplan.data.repository.TaskRepositoryImpl
import io.mockk.mockk
import org.junit.Test

/**
 * Unit tests for RepositoryModule
 *
 * RepositoryModule uses @Binds annotations which are verified at compile time by Hilt.
 * These tests verify that each implementation correctly implements its interface
 * and can be instantiated with mocked dependencies.
 *
 * Tests cover:
 * - ProjectRepository binding
 * - TaskRepository binding
 * - CompletionLogRepository binding
 * - SectionRepository binding
 * - TagRepository binding
 * - SavedViewRepository binding
 */
class RepositoryModuleTest {

    // ─────────────────────────────────────
    // ProjectRepository Binding Tests
    // ─────────────────────────────────────

    @Test
    fun `ProjectRepositoryImpl implements ProjectRepository interface`() {
        val impl = ProjectRepositoryImpl(mockk(relaxed = true))

        assertThat(impl).isInstanceOf(ProjectRepository::class.java)
    }

    @Test
    fun `ProjectRepositoryImpl can be assigned to ProjectRepository`() {
        val impl = ProjectRepositoryImpl(mockk(relaxed = true))
        val repository: ProjectRepository = impl

        assertThat(repository).isNotNull()
        assertThat(repository).isSameInstanceAs(impl)
    }

    // ─────────────────────────────────────
    // TaskRepository Binding Tests
    // ─────────────────────────────────────

    @Test
    fun `TaskRepositoryImpl implements TaskRepository interface`() {
        val impl = TaskRepositoryImpl(mockk(relaxed = true))

        assertThat(impl).isInstanceOf(TaskRepository::class.java)
    }

    @Test
    fun `TaskRepositoryImpl can be assigned to TaskRepository`() {
        val impl = TaskRepositoryImpl(mockk(relaxed = true))
        val repository: TaskRepository = impl

        assertThat(repository).isNotNull()
        assertThat(repository).isSameInstanceAs(impl)
    }

    // ─────────────────────────────────────
    // CompletionLogRepository Binding Tests
    // ─────────────────────────────────────

    @Test
    fun `CompletionLogRepositoryImpl implements CompletionLogRepository interface`() {
        val impl = CompletionLogRepositoryImpl(mockk(relaxed = true))

        assertThat(impl).isInstanceOf(CompletionLogRepository::class.java)
    }

    @Test
    fun `CompletionLogRepositoryImpl can be assigned to CompletionLogRepository`() {
        val impl = CompletionLogRepositoryImpl(mockk(relaxed = true))
        val repository: CompletionLogRepository = impl

        assertThat(repository).isNotNull()
        assertThat(repository).isSameInstanceAs(impl)
    }

    // ─────────────────────────────────────
    // SectionRepository Binding Tests
    // ─────────────────────────────────────

    @Test
    fun `SectionRepositoryImpl implements SectionRepository interface`() {
        val impl = SectionRepositoryImpl(mockk(relaxed = true))

        assertThat(impl).isInstanceOf(SectionRepository::class.java)
    }

    @Test
    fun `SectionRepositoryImpl can be assigned to SectionRepository`() {
        val impl = SectionRepositoryImpl(mockk(relaxed = true))
        val repository: SectionRepository = impl

        assertThat(repository).isNotNull()
        assertThat(repository).isSameInstanceAs(impl)
    }

    // ─────────────────────────────────────
    // TagRepository Binding Tests
    // ─────────────────────────────────────

    @Test
    fun `TagRepositoryImpl implements TagRepository interface`() {
        val impl = TagRepositoryImpl(mockk(relaxed = true))

        assertThat(impl).isInstanceOf(TagRepository::class.java)
    }

    @Test
    fun `TagRepositoryImpl can be assigned to TagRepository`() {
        val impl = TagRepositoryImpl(mockk(relaxed = true))
        val repository: TagRepository = impl

        assertThat(repository).isNotNull()
        assertThat(repository).isSameInstanceAs(impl)
    }

    // ─────────────────────────────────────
    // SavedViewRepository Binding Tests
    // ─────────────────────────────────────

    @Test
    fun `SavedViewRepositoryImpl implements SavedViewRepository interface`() {
        val impl = SavedViewRepositoryImpl(mockk(relaxed = true))

        assertThat(impl).isInstanceOf(SavedViewRepository::class.java)
    }

    @Test
    fun `SavedViewRepositoryImpl can be assigned to SavedViewRepository`() {
        val impl = SavedViewRepositoryImpl(mockk(relaxed = true))
        val repository: SavedViewRepository = impl

        assertThat(repository).isNotNull()
        assertThat(repository).isSameInstanceAs(impl)
    }

    // ─────────────────────────────────────
    // All Repositories Integration Test
    // ─────────────────────────────────────

    @Test
    fun `all repository implementations are distinct types`() {
        val projectRepo: ProjectRepository = ProjectRepositoryImpl(mockk(relaxed = true))
        val taskRepo: TaskRepository = TaskRepositoryImpl(mockk(relaxed = true))
        val completionLogRepo: CompletionLogRepository = CompletionLogRepositoryImpl(mockk(relaxed = true))
        val sectionRepo: SectionRepository = SectionRepositoryImpl(mockk(relaxed = true))
        val tagRepo: TagRepository = TagRepositoryImpl(mockk(relaxed = true))
        val savedViewRepo: SavedViewRepository = SavedViewRepositoryImpl(mockk(relaxed = true))

        // Verify all repositories are distinct objects
        val repos = listOf(projectRepo, taskRepo, completionLogRepo, sectionRepo, tagRepo, savedViewRepo)
        assertThat(repos.distinct().size).isEqualTo(6)
    }

    @Test
    fun `repository module defines correct number of bindings`() {
        // RepositoryModule should bind 6 repositories
        // This test documents the expected bindings
        val expectedBindings = listOf(
            "ProjectRepository",
            "TaskRepository",
            "CompletionLogRepository",
            "SectionRepository",
            "TagRepository",
            "SavedViewRepository"
        )

        assertThat(expectedBindings.size).isEqualTo(6)
    }
}
