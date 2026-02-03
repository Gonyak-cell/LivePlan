package com.liveplan.data.database.entity

import com.google.common.truth.Truth.assertThat
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.Priority
import com.liveplan.core.model.Project
import com.liveplan.core.model.ProjectStatus
import com.liveplan.core.model.RecurrenceBehavior
import com.liveplan.core.model.RecurrenceKind
import com.liveplan.core.model.RecurrenceRule
import com.liveplan.core.model.Section
import com.liveplan.core.model.Tag
import com.liveplan.core.model.Task
import com.liveplan.core.model.WorkflowState
import org.junit.Test

/**
 * Tests for Entity <-> Domain mappers
 *
 * Verifies round-trip conversion for all entities
 */
class EntityMapperTest {

    // ─────────────────────────────────────
    // Project Entity Mapper
    // ─────────────────────────────────────

    @Test
    fun `Project round-trip conversion`() {
        val now = System.currentTimeMillis()
        val original = Project(
            id = "project-1",
            title = "Test Project",
            startDate = now,
            dueDate = now + 86400000L,
            note = "Project note",
            status = ProjectStatus.ACTIVE,
            createdAt = now,
            updatedAt = now
        )

        val entity = ProjectEntity.fromDomain(original)
        val converted = entity.toDomain()

        assertThat(converted.id).isEqualTo(original.id)
        assertThat(converted.title).isEqualTo(original.title)
        assertThat(converted.startDate).isEqualTo(original.startDate)
        assertThat(converted.dueDate).isEqualTo(original.dueDate)
        assertThat(converted.note).isEqualTo(original.note)
        assertThat(converted.status).isEqualTo(original.status)
        assertThat(converted.createdAt).isEqualTo(original.createdAt)
        assertThat(converted.updatedAt).isEqualTo(original.updatedAt)
    }

    @Test
    fun `Project with null optional fields`() {
        val original = Project(
            id = "project-1",
            title = "Minimal Project",
            startDate = System.currentTimeMillis(),
            dueDate = null,
            note = null
        )

        val entity = ProjectEntity.fromDomain(original)
        val converted = entity.toDomain()

        assertThat(converted.dueDate).isNull()
        assertThat(converted.note).isNull()
    }

    // ─────────────────────────────────────
    // Task Entity Mapper
    // ─────────────────────────────────────

    @Test
    fun `Task round-trip conversion with all fields`() {
        val now = System.currentTimeMillis()
        val original = Task(
            id = "task-1",
            projectId = "project-1",
            title = "Full Task",
            sectionId = "section-1",
            tagIds = listOf("tag-1", "tag-2"),
            priority = Priority.P1,
            workflowState = WorkflowState.DOING,
            startAt = now,
            dueAt = now + 86400000L,
            note = "Task note",
            recurrenceRule = RecurrenceRule.daily(now),
            recurrenceBehavior = RecurrenceBehavior.ROLLOVER,
            nextOccurrenceDueAt = now + 86400000L,
            blockedByTaskIds = listOf("blocker-1"),
            createdAt = now,
            updatedAt = now
        )

        val entity = TaskEntity.fromDomain(original)
        val converted = entity.toDomain()

        assertThat(converted.id).isEqualTo(original.id)
        assertThat(converted.projectId).isEqualTo(original.projectId)
        assertThat(converted.title).isEqualTo(original.title)
        assertThat(converted.sectionId).isEqualTo(original.sectionId)
        assertThat(converted.tagIds).isEqualTo(original.tagIds)
        assertThat(converted.priority).isEqualTo(original.priority)
        assertThat(converted.workflowState).isEqualTo(original.workflowState)
        assertThat(converted.startAt).isEqualTo(original.startAt)
        assertThat(converted.dueAt).isEqualTo(original.dueAt)
        assertThat(converted.note).isEqualTo(original.note)
        assertThat(converted.recurrenceRule?.kind).isEqualTo(RecurrenceKind.DAILY)
        assertThat(converted.recurrenceBehavior).isEqualTo(original.recurrenceBehavior)
        assertThat(converted.nextOccurrenceDueAt).isEqualTo(original.nextOccurrenceDueAt)
        assertThat(converted.blockedByTaskIds).isEqualTo(original.blockedByTaskIds)
        assertThat(converted.createdAt).isEqualTo(original.createdAt)
        assertThat(converted.updatedAt).isEqualTo(original.updatedAt)
    }

    @Test
    fun `Task with minimal fields (oneOff)`() {
        val now = System.currentTimeMillis()
        val original = Task(
            id = "task-1",
            projectId = "project-1",
            title = "Simple Task",
            createdAt = now
        )

        val entity = TaskEntity.fromDomain(original)
        val converted = entity.toDomain()

        assertThat(converted.id).isEqualTo(original.id)
        assertThat(converted.sectionId).isNull()
        assertThat(converted.tagIds).isEmpty()
        assertThat(converted.priority).isEqualTo(Priority.P4)
        assertThat(converted.workflowState).isEqualTo(WorkflowState.TODO)
        assertThat(converted.recurrenceRule).isNull()
        assertThat(converted.blockedByTaskIds).isEmpty()
    }

    @Test
    fun `Task tagIds JSON serialization`() {
        val original = Task(
            id = "task-1",
            projectId = "project-1",
            title = "Tagged Task",
            tagIds = listOf("tag-1", "tag-2", "tag-3"),
            createdAt = System.currentTimeMillis()
        )

        val entity = TaskEntity.fromDomain(original)
        val converted = entity.toDomain()

        assertThat(converted.tagIds).containsExactly("tag-1", "tag-2", "tag-3")
    }

    // ─────────────────────────────────────
    // Section Entity Mapper
    // ─────────────────────────────────────

    @Test
    fun `Section round-trip conversion`() {
        val original = Section(
            id = "section-1",
            projectId = "project-1",
            title = "To Do",
            orderIndex = 0
        )

        val entity = SectionEntity.fromDomain(original)
        val converted = entity.toDomain()

        assertThat(converted.id).isEqualTo(original.id)
        assertThat(converted.projectId).isEqualTo(original.projectId)
        assertThat(converted.title).isEqualTo(original.title)
        assertThat(converted.orderIndex).isEqualTo(original.orderIndex)
    }

    // ─────────────────────────────────────
    // Tag Entity Mapper
    // ─────────────────────────────────────

    @Test
    fun `Tag round-trip conversion`() {
        val original = Tag(
            id = "tag-1",
            name = "Work",
            colorToken = "blue"
        )

        val entity = TagEntity.fromDomain(original)
        val converted = entity.toDomain()

        assertThat(converted.id).isEqualTo(original.id)
        assertThat(converted.name).isEqualTo(original.name)
        assertThat(converted.colorToken).isEqualTo(original.colorToken)
    }

    @Test
    fun `Tag with null colorToken`() {
        val original = Tag(
            id = "tag-1",
            name = "Personal",
            colorToken = null
        )

        val entity = TagEntity.fromDomain(original)
        val converted = entity.toDomain()

        assertThat(converted.colorToken).isNull()
    }

    // ─────────────────────────────────────
    // CompletionLog Entity Mapper
    // ─────────────────────────────────────

    @Test
    fun `CompletionLog round-trip conversion`() {
        val now = System.currentTimeMillis()
        val original = CompletionLog(
            id = "log-1",
            taskId = "task-1",
            completedAt = now,
            occurrenceKey = "2026-02-03"
        )

        val entity = CompletionLogEntity.fromDomain(original)
        val converted = entity.toDomain()

        assertThat(converted.id).isEqualTo(original.id)
        assertThat(converted.taskId).isEqualTo(original.taskId)
        assertThat(converted.completedAt).isEqualTo(original.completedAt)
        assertThat(converted.occurrenceKey).isEqualTo(original.occurrenceKey)
    }

    @Test
    fun `CompletionLog with ONCE_KEY`() {
        val original = CompletionLog(
            id = "log-1",
            taskId = "task-1",
            completedAt = System.currentTimeMillis(),
            occurrenceKey = CompletionLog.ONCE_KEY
        )

        val entity = CompletionLogEntity.fromDomain(original)
        val converted = entity.toDomain()

        assertThat(converted.occurrenceKey).isEqualTo(CompletionLog.ONCE_KEY)
    }
}
