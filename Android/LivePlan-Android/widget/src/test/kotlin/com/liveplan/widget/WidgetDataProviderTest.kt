package com.liveplan.widget

import android.content.Context
import com.google.common.truth.Truth.assertThat
import com.liveplan.core.model.AppSettings
import com.liveplan.core.model.CompletionLog
import com.liveplan.core.model.Priority
import com.liveplan.core.model.PrivacyMode
import com.liveplan.core.model.Project
import com.liveplan.core.model.ProjectStatus
import com.liveplan.core.model.Task
import com.liveplan.core.privacy.PrivacyMasker
import com.liveplan.core.repository.CompletionLogRepository
import com.liveplan.core.repository.ProjectRepository
import com.liveplan.core.repository.TaskRepository
import com.liveplan.core.selection.OutstandingComputer
import com.liveplan.core.selection.SelectionPolicy
import com.liveplan.data.datastore.AppSettingsDataStore
import com.liveplan.widget.data.WidgetDataProvider
import com.liveplan.widget.data.WidgetState
import io.mockk.coEvery
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test

/**
 * Tests for WidgetDataProvider
 */
class WidgetDataProviderTest {

    private lateinit var context: Context
    private lateinit var projectRepository: ProjectRepository
    private lateinit var taskRepository: TaskRepository
    private lateinit var completionLogRepository: CompletionLogRepository
    private lateinit var appSettingsDataStore: AppSettingsDataStore
    private lateinit var outstandingComputer: OutstandingComputer
    private lateinit var widgetDataProvider: WidgetDataProvider

    private val testProject = Project(
        id = "project-1",
        title = "Test Project",
        startDate = System.currentTimeMillis(),
        status = ProjectStatus.ACTIVE
    )

    private val testTask = Task(
        id = "task-1",
        projectId = "project-1",
        title = "Test Task",
        priority = Priority.P2
    )

    @Before
    fun setup() {
        context = mockk(relaxed = true)
        projectRepository = mockk()
        taskRepository = mockk()
        completionLogRepository = mockk()
        appSettingsDataStore = mockk()
        outstandingComputer = OutstandingComputer(PrivacyMasker())

        widgetDataProvider = WidgetDataProvider(
            context = context,
            projectRepository = projectRepository,
            taskRepository = taskRepository,
            completionLogRepository = completionLogRepository,
            appSettingsDataStore = appSettingsDataStore,
            outstandingComputer = outstandingComputer
        )
    }

    @Test
    fun `getWidgetState returns Success with tasks`() = runTest {
        // Given
        every { projectRepository.getAllProjects() } returns flowOf(listOf(testProject))
        every { taskRepository.getAllTasks() } returns flowOf(listOf(testTask))
        every { completionLogRepository.getAllLogs() } returns flowOf(emptyList())
        every { appSettingsDataStore.settings } returns flowOf(
            AppSettings(
                privacyMode = PrivacyMode.LEVEL_0,
                lockscreenSelectionMode = SelectionPolicy.TODAY_OVERVIEW
            )
        )

        // When
        val result = widgetDataProvider.getWidgetState()

        // Then
        assertThat(result).isInstanceOf(WidgetState.Success::class.java)
        val success = result as WidgetState.Success
        assertThat(success.summary.displayList).hasSize(1)
        assertThat(success.summary.counters.outstandingTotal).isEqualTo(1)
    }

    @Test
    fun `getWidgetState returns Success empty when no tasks`() = runTest {
        // Given
        every { projectRepository.getAllProjects() } returns flowOf(listOf(testProject))
        every { taskRepository.getAllTasks() } returns flowOf(emptyList())
        every { completionLogRepository.getAllLogs() } returns flowOf(emptyList())
        every { appSettingsDataStore.settings } returns flowOf(AppSettings())

        // When
        val result = widgetDataProvider.getWidgetState()

        // Then
        assertThat(result).isInstanceOf(WidgetState.Success::class.java)
        val success = result as WidgetState.Success
        assertThat(success.isEmpty).isTrue()
    }

    @Test
    fun `getWidgetState excludes completed tasks`() = runTest {
        // Given
        val completionLog = CompletionLog(
            taskId = "task-1",
            occurrenceKey = CompletionLog.ONCE_KEY
        )
        every { projectRepository.getAllProjects() } returns flowOf(listOf(testProject))
        every { taskRepository.getAllTasks() } returns flowOf(listOf(testTask))
        every { completionLogRepository.getAllLogs() } returns flowOf(listOf(completionLog))
        every { appSettingsDataStore.settings } returns flowOf(AppSettings())

        // When
        val result = widgetDataProvider.getWidgetState()

        // Then
        assertThat(result).isInstanceOf(WidgetState.Success::class.java)
        val success = result as WidgetState.Success
        assertThat(success.summary.displayList).isEmpty()
        assertThat(success.summary.counters.outstandingTotal).isEqualTo(0)
    }

    @Test
    fun `getWidgetState returns Error on exception`() = runTest {
        // Given
        every { projectRepository.getAllProjects() } throws RuntimeException("Database error")

        // When
        val result = widgetDataProvider.getWidgetState()

        // Then
        assertThat(result).isInstanceOf(WidgetState.Error::class.java)
    }

    @Test
    fun `getWidgetState applies privacy masking Level 1`() = runTest {
        // Given
        every { projectRepository.getAllProjects() } returns flowOf(listOf(testProject))
        every { taskRepository.getAllTasks() } returns flowOf(listOf(testTask))
        every { completionLogRepository.getAllLogs() } returns flowOf(emptyList())
        every { appSettingsDataStore.settings } returns flowOf(
            AppSettings(privacyMode = PrivacyMode.LEVEL_1)
        )

        // When
        val result = widgetDataProvider.getWidgetState()

        // Then
        assertThat(result).isInstanceOf(WidgetState.Success::class.java)
        val success = result as WidgetState.Success
        // Level 1 masks titles
        assertThat(success.summary.displayList.first().maskedTitle)
            .isNotEqualTo("Test Task")
    }

    @Test
    fun `getWidgetState uses pinned project when available`() = runTest {
        // Given
        val pinnedProject = testProject.copy(id = "pinned-1")
        val pinnedTask = testTask.copy(id = "task-pinned", projectId = "pinned-1", title = "Pinned Task")
        val otherTask = testTask.copy(id = "task-other", projectId = "other-1", title = "Other Task")

        every { projectRepository.getAllProjects() } returns flowOf(listOf(pinnedProject))
        every { taskRepository.getAllTasks() } returns flowOf(listOf(pinnedTask, otherTask))
        every { completionLogRepository.getAllLogs() } returns flowOf(emptyList())
        every { appSettingsDataStore.settings } returns flowOf(
            AppSettings(
                pinnedProjectId = "pinned-1",
                lockscreenSelectionMode = SelectionPolicy.PINNED_FIRST,
                privacyMode = PrivacyMode.LEVEL_0
            )
        )

        // When
        val result = widgetDataProvider.getWidgetState()

        // Then
        assertThat(result).isInstanceOf(WidgetState.Success::class.java)
        val success = result as WidgetState.Success
        // Should only show pinned project's tasks
        assertThat(success.summary.displayList).hasSize(1)
        assertThat(success.summary.displayList.first().task.title).isEqualTo("Pinned Task")
    }

    @Test
    fun `getPrivacyMode returns default on error`() = runTest {
        // Given
        every { appSettingsDataStore.settings } throws RuntimeException("Error")

        // When
        val result = widgetDataProvider.getPrivacyMode()

        // Then
        assertThat(result).isEqualTo(PrivacyMode.DEFAULT)
    }

    @Test
    fun `getPrivacyMode returns stored privacy mode`() = runTest {
        // Given
        every { appSettingsDataStore.settings } returns flowOf(
            AppSettings(privacyMode = PrivacyMode.LEVEL_2)
        )

        // When
        val result = widgetDataProvider.getPrivacyMode()

        // Then
        assertThat(result).isEqualTo(PrivacyMode.LEVEL_2)
    }
}
