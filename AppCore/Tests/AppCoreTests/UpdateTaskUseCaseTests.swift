import XCTest
@testable import AppCore

/// UpdateTaskUseCase 테스트
/// - testing.md B 섹션: 필수 테스트 케이스 준수
/// - data-model.md A4: Task 제약 조건 검증
final class UpdateTaskUseCaseTests: XCTestCase {

    private var taskRepository: MockTaskRepository!
    private var projectRepository: MockProjectRepository!
    private var sut: UpdateTaskUseCase!

    override func setUp() {
        super.setUp()
        taskRepository = MockTaskRepository()
        projectRepository = MockProjectRepository()
        sut = UpdateTaskUseCase(
            taskRepository: taskRepository,
            projectRepository: projectRepository
        )
    }

    override func tearDown() {
        taskRepository = nil
        projectRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Task Not Found

    func testExecute_TaskNotFound_ThrowsError() async throws {
        // Given: 존재하지 않는 태스크 ID

        // When/Then
        do {
            _ = try await sut.execute(taskId: "nonexistent", title: "New Title")
            XCTFail("Expected error")
        } catch let error as UpdateTaskError {
            XCTAssertEqual(error, .taskNotFound("nonexistent"))
        }
    }

    // MARK: - Title Update

    func testExecute_UpdateTitle_Success() async throws {
        // Given
        let project = Project(title: "Test Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Original Title")
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, title: "New Title")

        // Then
        XCTAssertEqual(updated.title, "New Title")
        XCTAssertGreaterThan(updated.updatedAt, task.updatedAt)
    }

    func testExecute_TrimmedTitle() async throws {
        // Given
        let project = Project(title: "Test Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Original")
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, title: "  Trimmed Title  ")

        // Then
        XCTAssertEqual(updated.title, "Trimmed Title")
    }

    func testExecute_EmptyTitle_ThrowsError() async throws {
        // Given
        let project = Project(title: "Test Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Original")
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When/Then
        do {
            _ = try await sut.execute(taskId: task.id, title: "   ")
            XCTFail("Expected error")
        } catch let error as UpdateTaskError {
            XCTAssertEqual(error, .emptyTitle)
        }
    }

    // MARK: - Project Change

    func testExecute_ChangeProject_Success() async throws {
        // Given
        let project1 = Project(title: "Project 1", startDate: Date())
        let project2 = Project(title: "Project 2", startDate: Date())
        let task = Task(
            projectId: project1.id,
            title: "Task",
            sectionId: "section1",
            blockedByTaskIds: ["other-task"]
        )
        try await projectRepository.save(project1)
        try await projectRepository.save(project2)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, projectId: project2.id)

        // Then
        XCTAssertEqual(updated.projectId, project2.id)
        // 프로젝트 변경 시 섹션/의존성 초기화 확인
        XCTAssertNil(updated.sectionId)
        XCTAssertTrue(updated.blockedByTaskIds.isEmpty)
    }

    func testExecute_ChangeProject_NotFound_ThrowsError() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task")
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When/Then
        do {
            _ = try await sut.execute(taskId: task.id, projectId: "nonexistent")
            XCTFail("Expected error")
        } catch let error as UpdateTaskError {
            XCTAssertEqual(error, .projectNotFound("nonexistent"))
        }
    }

    // MARK: - Task Type Update

    func testExecute_ChangeTaskType() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task", taskType: .oneOff)
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, taskType: .dailyRecurring)

        // Then
        XCTAssertEqual(updated.taskType, .dailyRecurring)
    }

    // MARK: - Due Date Update

    func testExecute_SetDueDate() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task")
        try await projectRepository.save(project)
        try await taskRepository.save(task)
        let newDueDate = Date().addingTimeInterval(86400)

        // When
        let updated = try await sut.execute(taskId: task.id, dueDate: .some(newDueDate))

        // Then
        XCTAssertEqual(updated.dueDate, newDueDate)
    }

    func testExecute_RemoveDueDate() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let dueDate = Date().addingTimeInterval(86400)
        let task = Task(projectId: project.id, title: "Task", dueDate: dueDate)
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, dueDate: .none)

        // Then
        XCTAssertNil(updated.dueDate)
    }

    // MARK: - Priority Update

    func testExecute_ChangePriority() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task", priority: .p4)
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, priority: .p1)

        // Then
        XCTAssertEqual(updated.priority, .p1)
    }

    // MARK: - Workflow State Update

    func testExecute_ChangeWorkflowState() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task", workflowState: .todo)
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, workflowState: .doing)

        // Then
        XCTAssertEqual(updated.workflowState, .doing)
    }

    // MARK: - Section Update

    func testExecute_ChangeSection() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task")
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, sectionId: .some("section1"))

        // Then
        XCTAssertEqual(updated.sectionId, "section1")
    }

    func testExecute_RemoveSection() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task", sectionId: "section1")
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, sectionId: .none)

        // Then
        XCTAssertNil(updated.sectionId)
    }

    // MARK: - Tags Update

    func testExecute_UpdateTags() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task", tagIds: ["tag1"])
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, tagIds: ["tag2", "tag3"])

        // Then
        XCTAssertEqual(updated.tagIds, ["tag2", "tag3"])
    }

    // MARK: - Note Update

    func testExecute_SetNote() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task")
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, note: .some("New note"))

        // Then
        XCTAssertEqual(updated.note, "New note")
    }

    func testExecute_RemoveNote() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task", note: "Old note")
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, note: .none)

        // Then
        XCTAssertNil(updated.note)
    }

    // MARK: - Dependencies (blockedByTaskIds)

    func testExecute_SetBlockedByTaskIds_Success() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task1 = Task(projectId: project.id, title: "Task 1")
        let task2 = Task(projectId: project.id, title: "Task 2")
        try await projectRepository.save(project)
        try await taskRepository.save(task1)
        try await taskRepository.save(task2)

        // When
        let updated = try await sut.execute(taskId: task2.id, blockedByTaskIds: [task1.id])

        // Then
        XCTAssertEqual(updated.blockedByTaskIds, [task1.id])
    }

    func testExecute_SelfReference_ThrowsError() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task")
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When/Then
        do {
            _ = try await sut.execute(taskId: task.id, blockedByTaskIds: [task.id])
            XCTFail("Expected error")
        } catch let error as UpdateTaskError {
            XCTAssertEqual(error, .selfReference)
        }
    }

    func testExecute_BlockedTaskNotFound_ThrowsError() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task")
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When/Then
        do {
            _ = try await sut.execute(taskId: task.id, blockedByTaskIds: ["nonexistent"])
            XCTFail("Expected error")
        } catch let error as UpdateTaskError {
            XCTAssertEqual(error, .blockedTaskNotFound("nonexistent"))
        }
    }

    func testExecute_CrossProjectDependency_ThrowsError() async throws {
        // Given
        let project1 = Project(title: "Project 1", startDate: Date())
        let project2 = Project(title: "Project 2", startDate: Date())
        let task1 = Task(projectId: project1.id, title: "Task 1")
        let task2 = Task(projectId: project2.id, title: "Task 2")
        try await projectRepository.save(project1)
        try await projectRepository.save(project2)
        try await taskRepository.save(task1)
        try await taskRepository.save(task2)

        // When/Then: task2가 다른 프로젝트의 task1에 의존하려고 함
        do {
            _ = try await sut.execute(taskId: task2.id, blockedByTaskIds: [task1.id])
            XCTFail("Expected error")
        } catch let error as UpdateTaskError {
            XCTAssertEqual(error, .crossProjectDependency(task1.id))
        }
    }

    // MARK: - Recurrence Rule

    func testExecute_SetRecurrenceRule() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task")
        try await projectRepository.save(project)
        try await taskRepository.save(task)
        let rule = RecurrenceRule.weekly(weekdays: [.monday, .wednesday])

        // When
        let updated = try await sut.execute(taskId: task.id, recurrenceRule: .some(rule))

        // Then
        XCTAssertNotNil(updated.recurrenceRule)
        XCTAssertEqual(updated.recurrenceRule?.kind, .weekly)
    }

    func testExecute_RemoveRecurrenceRule() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(
            projectId: project.id,
            title: "Task",
            recurrenceRule: .daily()
        )
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, recurrenceRule: .none)

        // Then
        XCTAssertNil(updated.recurrenceRule)
    }

    func testExecute_InvalidRecurrenceRule_ThrowsError() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Task")
        try await projectRepository.save(project)
        try await taskRepository.save(task)
        // weekly인데 weekdays가 비어있는 잘못된 규칙
        let invalidRule = RecurrenceRule(kind: .weekly, weekdays: [])

        // When/Then
        do {
            _ = try await sut.execute(taskId: task.id, recurrenceRule: .some(invalidRule))
            XCTFail("Expected error")
        } catch let error as UpdateTaskError {
            XCTAssertEqual(error, .invalidRecurrenceRule(.weeklyWithoutWeekdays))
        }
    }

    // MARK: - Recurrence Behavior

    func testExecute_SetRecurrenceBehavior() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(
            projectId: project.id,
            title: "Task",
            recurrenceRule: .weekly(weekdays: [.monday])
        )
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When
        let updated = try await sut.execute(taskId: task.id, recurrenceBehavior: .some(.habitReset))

        // Then
        XCTAssertEqual(updated.recurrenceBehavior, .habitReset)
    }

    // MARK: - Multiple Updates

    func testExecute_MultipleUpdates() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let task = Task(projectId: project.id, title: "Original", priority: .p4)
        try await projectRepository.save(project)
        try await taskRepository.save(task)
        let newDueDate = Date().addingTimeInterval(86400)

        // When
        let updated = try await sut.execute(
            taskId: task.id,
            title: "Updated Title",
            dueDate: .some(newDueDate),
            priority: .p1,
            workflowState: .doing,
            tagIds: ["important"]
        )

        // Then
        XCTAssertEqual(updated.title, "Updated Title")
        XCTAssertEqual(updated.dueDate, newDueDate)
        XCTAssertEqual(updated.priority, .p1)
        XCTAssertEqual(updated.workflowState, .doing)
        XCTAssertEqual(updated.tagIds, ["important"])
    }

    // MARK: - No Changes

    func testExecute_NoChanges_UpdatesTimestamp() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let originalUpdatedAt = Date().addingTimeInterval(-100)
        let task = Task(
            projectId: project.id,
            title: "Task",
            updatedAt: originalUpdatedAt
        )
        try await projectRepository.save(project)
        try await taskRepository.save(task)

        // When: 아무 변경 없이 호출
        let updated = try await sut.execute(taskId: task.id)

        // Then: updatedAt만 갱신됨
        XCTAssertEqual(updated.title, "Task")
        XCTAssertGreaterThan(updated.updatedAt, originalUpdatedAt)
    }
}

// MARK: - Mock Repositories

private final class MockTaskRepository: TaskRepository, @unchecked Sendable {
    private var tasks: [String: Task] = [:]

    func loadAll() async throws -> [Task] {
        Array(tasks.values)
    }

    func load(id: String) async throws -> Task? {
        tasks[id]
    }

    func loadByProject(projectId: String) async throws -> [Task] {
        tasks.values.filter { $0.projectId == projectId }
    }

    func save(_ task: Task) async throws {
        tasks[task.id] = task
    }

    func delete(id: String) async throws {
        tasks.removeValue(forKey: id)
    }

    func deleteByProject(projectId: String) async throws {
        tasks = tasks.filter { $0.value.projectId != projectId }
    }
}

private final class MockProjectRepository: ProjectRepository, @unchecked Sendable {
    private var projects: [String: Project] = [:]

    func loadAll() async throws -> [Project] {
        Array(projects.values)
    }

    func load(id: String) async throws -> Project? {
        projects[id]
    }

    func save(_ project: Project) async throws {
        projects[project.id] = project
    }

    func delete(id: String) async throws {
        projects.removeValue(forKey: id)
    }

    func getOrCreateInbox() async throws -> Project {
        if let inbox = projects.values.first(where: { $0.isInbox }) {
            return inbox
        }
        let inbox = Project.createInbox()
        projects[inbox.id] = inbox
        return inbox
    }
}
