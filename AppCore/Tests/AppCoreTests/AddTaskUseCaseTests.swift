import XCTest
@testable import AppCore

/// AddTaskUseCase 테스트
/// - testing.md A1: AppCore 단위 테스트 필수
/// - data-model.md A4: Task Phase 2 필드 지원 검증
/// - intents.md: QuickAddTask 정책 (pinned 우선, 없으면 Inbox)
final class AddTaskUseCaseTests: XCTestCase {

    private var taskRepository: MockTaskRepository!
    private var projectRepository: MockProjectRepository!
    private var sectionRepository: MockSectionRepository!
    private var sut: AddTaskUseCase!

    override func setUp() {
        super.setUp()
        taskRepository = MockTaskRepository()
        projectRepository = MockProjectRepository()
        sectionRepository = MockSectionRepository()
        sut = AddTaskUseCase(
            taskRepository: taskRepository,
            projectRepository: projectRepository,
            sectionRepository: sectionRepository
        )
    }

    override func tearDown() {
        taskRepository = nil
        projectRepository = nil
        sectionRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Task Creation

    func testExecute_BasicTask_Success() async throws {
        // Given
        let project = Project(title: "Test Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "New Task",
            projectId: project.id
        )

        // Then
        XCTAssertEqual(task.title, "New Task")
        XCTAssertEqual(task.projectId, project.id)
        XCTAssertEqual(task.taskType, .oneOff)
        XCTAssertEqual(task.priority, .defaultPriority)
        XCTAssertEqual(task.workflowState, .defaultState)
        XCTAssertTrue(task.tagIds.isEmpty)
        XCTAssertNil(task.sectionId)
        XCTAssertNil(task.note)
    }

    func testExecute_TrimmedTitle() async throws {
        // Given
        let project = Project(title: "Test Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "  Trimmed Title  ",
            projectId: project.id
        )

        // Then
        XCTAssertEqual(task.title, "Trimmed Title")
    }

    func testExecute_EmptyTitle_ThrowsError() async throws {
        // Given
        let project = Project(title: "Test Project", startDate: Date())
        try await projectRepository.save(project)

        // When/Then
        do {
            _ = try await sut.execute(title: "   ", projectId: project.id)
            XCTFail("Expected error")
        } catch let error as AddTaskError {
            XCTAssertEqual(error, .emptyTitle)
        }
    }

    func testExecute_ProjectNotFound_ThrowsError() async throws {
        // When/Then
        do {
            _ = try await sut.execute(title: "Task", projectId: "nonexistent")
            XCTFail("Expected error")
        } catch let error as AddTaskError {
            XCTAssertEqual(error, .projectNotFound("nonexistent"))
        }
    }

    // MARK: - Project Selection (intents.md QuickAdd Policy)

    func testExecute_NoProjectId_UsesPinnedProject() async throws {
        // Given
        let pinnedProject = Project(title: "Pinned", startDate: Date())
        try await projectRepository.save(pinnedProject)

        // When: projectId 없이, pinnedProjectId만 제공
        let task = try await sut.execute(
            title: "Task",
            pinnedProjectId: pinnedProject.id
        )

        // Then: pinned 프로젝트 사용
        XCTAssertEqual(task.projectId, pinnedProject.id)
    }

    func testExecute_NoProjectId_InactivePinned_FallsBackToInbox() async throws {
        // Given: archived 상태의 pinned 프로젝트
        var pinnedProject = Project(title: "Archived Pinned", startDate: Date())
        pinnedProject.status = .archived
        try await projectRepository.save(pinnedProject)

        // When
        let task = try await sut.execute(
            title: "Task",
            pinnedProjectId: pinnedProject.id
        )

        // Then: Inbox로 폴백
        let inbox = try await projectRepository.getOrCreateInbox()
        XCTAssertEqual(task.projectId, inbox.id)
    }

    func testExecute_NoProjectId_NoPinned_FallsBackToInbox() async throws {
        // When: projectId, pinnedProjectId 모두 없음
        let task = try await sut.execute(title: "Task")

        // Then: Inbox 사용
        let inbox = try await projectRepository.getOrCreateInbox()
        XCTAssertEqual(task.projectId, inbox.id)
    }

    func testExecute_ExplicitProjectId_OverridesPinned() async throws {
        // Given
        let project1 = Project(title: "Project 1", startDate: Date())
        let project2 = Project(title: "Project 2 (Pinned)", startDate: Date())
        try await projectRepository.save(project1)
        try await projectRepository.save(project2)

        // When: 명시적 projectId가 pinned보다 우선
        let task = try await sut.execute(
            title: "Task",
            projectId: project1.id,
            pinnedProjectId: project2.id
        )

        // Then
        XCTAssertEqual(task.projectId, project1.id)
    }

    // MARK: - Task Type

    func testExecute_DailyRecurringTask() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "Daily Task",
            projectId: project.id,
            taskType: .dailyRecurring
        )

        // Then
        XCTAssertEqual(task.taskType, .dailyRecurring)
        XCTAssertTrue(task.isRecurring)
    }

    // MARK: - Due Date

    func testExecute_WithDueDate() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)
        let dueDate = Date().addingTimeInterval(86400) // 내일

        // When
        let task = try await sut.execute(
            title: "Task",
            projectId: project.id,
            dueDate: dueDate
        )

        // Then
        XCTAssertEqual(task.dueDate, dueDate)
    }

    // MARK: - Priority (Phase 2)

    func testExecute_WithPriority() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "Urgent Task",
            projectId: project.id,
            priority: .p1
        )

        // Then
        XCTAssertEqual(task.priority, .p1)
    }

    func testExecute_DefaultPriority() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "Task",
            projectId: project.id
        )

        // Then
        XCTAssertEqual(task.priority, .p4) // P4가 기본값
    }

    // MARK: - Tags (Phase 2)

    func testExecute_WithTags() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "Tagged Task",
            projectId: project.id,
            tagIds: ["tag1", "tag2", "tag3"]
        )

        // Then
        XCTAssertEqual(task.tagIds, ["tag1", "tag2", "tag3"])
        XCTAssertTrue(task.hasTags)
    }

    func testExecute_EmptyTags() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "Task",
            projectId: project.id,
            tagIds: []
        )

        // Then
        XCTAssertTrue(task.tagIds.isEmpty)
        XCTAssertFalse(task.hasTags)
    }

    // MARK: - Workflow State (Phase 2)

    func testExecute_WithWorkflowState() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "In Progress Task",
            projectId: project.id,
            workflowState: .doing
        )

        // Then
        XCTAssertEqual(task.workflowState, .doing)
        XCTAssertTrue(task.isInProgress)
    }

    func testExecute_DefaultWorkflowState() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "Task",
            projectId: project.id
        )

        // Then
        XCTAssertEqual(task.workflowState, .todo)
    }

    // MARK: - Section (Phase 2)

    func testExecute_WithSection_Success() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let section = Section(projectId: project.id, title: "Section 1")
        try await projectRepository.save(project)
        try await sectionRepository.save(section)

        // When
        let task = try await sut.execute(
            title: "Task in Section",
            projectId: project.id,
            sectionId: section.id
        )

        // Then
        XCTAssertEqual(task.sectionId, section.id)
    }

    func testExecute_SectionNotFound_ThrowsError() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When/Then
        do {
            _ = try await sut.execute(
                title: "Task",
                projectId: project.id,
                sectionId: "nonexistent-section"
            )
            XCTFail("Expected error")
        } catch let error as AddTaskError {
            XCTAssertEqual(error, .sectionNotFound("nonexistent-section"))
        }
    }

    func testExecute_SectionProjectMismatch_ThrowsError() async throws {
        // Given: 다른 프로젝트의 섹션
        let project1 = Project(title: "Project 1", startDate: Date())
        let project2 = Project(title: "Project 2", startDate: Date())
        let sectionOfProject2 = Section(projectId: project2.id, title: "Section in Project 2")
        try await projectRepository.save(project1)
        try await projectRepository.save(project2)
        try await sectionRepository.save(sectionOfProject2)

        // When/Then: project1에 project2의 섹션 지정 시도
        do {
            _ = try await sut.execute(
                title: "Task",
                projectId: project1.id,
                sectionId: sectionOfProject2.id
            )
            XCTFail("Expected error")
        } catch let error as AddTaskError {
            XCTAssertEqual(error, .sectionProjectMismatch(sectionId: sectionOfProject2.id, projectId: project1.id))
        }
    }

    func testExecute_WithoutSectionRepository_SectionValidationUnavailable() async throws {
        // Given: SectionRepository 없이 생성된 UseCase
        let sutWithoutSection = AddTaskUseCase(
            taskRepository: taskRepository,
            projectRepository: projectRepository,
            sectionRepository: nil
        )
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When/Then: sectionId 지정 시 에러
        do {
            _ = try await sutWithoutSection.execute(
                title: "Task",
                projectId: project.id,
                sectionId: "some-section"
            )
            XCTFail("Expected error")
        } catch let error as AddTaskError {
            XCTAssertEqual(error, .sectionValidationUnavailable)
        }
    }

    func testExecute_WithoutSectionRepository_NoSectionId_Success() async throws {
        // Given: SectionRepository 없이 생성된 UseCase
        let sutWithoutSection = AddTaskUseCase(
            taskRepository: taskRepository,
            projectRepository: projectRepository,
            sectionRepository: nil
        )
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When: sectionId 없이 생성
        let task = try await sutWithoutSection.execute(
            title: "Task",
            projectId: project.id
        )

        // Then: 정상 생성
        XCTAssertNil(task.sectionId)
    }

    // MARK: - Note (Phase 2)

    func testExecute_WithNote() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "Task with Note",
            projectId: project.id,
            note: "This is a detailed note"
        )

        // Then
        XCTAssertEqual(task.note, "This is a detailed note")
    }

    func testExecute_EmptyNote_BecomesNil() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When: 빈 문자열 노트
        let task = try await sut.execute(
            title: "Task",
            projectId: project.id,
            note: "   "
        )

        // Then: nil로 정리
        XCTAssertNil(task.note)
    }

    func testExecute_NoteIsTrimmed() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "Task",
            projectId: project.id,
            note: "  Trimmed note  "
        )

        // Then
        XCTAssertEqual(task.note, "Trimmed note")
    }

    // MARK: - All Phase 2 Fields Combined

    func testExecute_AllPhase2Fields() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        let section = Section(projectId: project.id, title: "Section")
        try await projectRepository.save(project)
        try await sectionRepository.save(section)
        let dueDate = Date().addingTimeInterval(86400)

        // When: 모든 Phase 2 필드 사용
        let task = try await sut.execute(
            title: "Full Featured Task",
            projectId: project.id,
            taskType: .dailyRecurring,
            dueDate: dueDate,
            priority: .p1,
            tagIds: ["urgent", "work"],
            workflowState: .doing,
            sectionId: section.id,
            note: "Important task notes"
        )

        // Then
        XCTAssertEqual(task.title, "Full Featured Task")
        XCTAssertEqual(task.projectId, project.id)
        XCTAssertEqual(task.taskType, .dailyRecurring)
        XCTAssertEqual(task.dueDate, dueDate)
        XCTAssertEqual(task.priority, .p1)
        XCTAssertEqual(task.tagIds, ["urgent", "work"])
        XCTAssertEqual(task.workflowState, .doing)
        XCTAssertEqual(task.sectionId, section.id)
        XCTAssertEqual(task.note, "Important task notes")
    }

    // MARK: - Backward Compatibility

    func testExecute_BackwardCompatibility_MinimalParams() async throws {
        // Given: 기존 호출과 동일한 최소 파라미터
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When: Phase 1 스타일 호출 (기본값만 사용)
        let task = try await sut.execute(
            title: "Simple Task",
            projectId: project.id
        )

        // Then: Phase 2 필드들이 기본값으로 설정됨
        XCTAssertEqual(task.priority, .p4)
        XCTAssertTrue(task.tagIds.isEmpty)
        XCTAssertEqual(task.workflowState, .todo)
        XCTAssertNil(task.sectionId)
        XCTAssertNil(task.note)
    }

    // MARK: - Persistence

    func testExecute_TaskIsSaved() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let task = try await sut.execute(
            title: "Task",
            projectId: project.id
        )

        // Then: 저장소에 저장되었는지 확인
        let savedTask = try await taskRepository.load(id: task.id)
        XCTAssertNotNil(savedTask)
        XCTAssertEqual(savedTask?.title, "Task")
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

private final class MockSectionRepository: SectionRepository, @unchecked Sendable {
    private var sections: [String: Section] = [:]

    func loadAll() async throws -> [Section] {
        Array(sections.values)
    }

    func load(id: String) async throws -> Section? {
        sections[id]
    }

    func loadByProject(projectId: String) async throws -> [Section] {
        sections.values.filter { $0.projectId == projectId }
    }

    func save(_ section: Section) async throws {
        sections[section.id] = section
    }

    func delete(id: String) async throws {
        sections.removeValue(forKey: id)
    }

    func deleteByProject(projectId: String) async throws {
        sections = sections.filter { $0.value.projectId != projectId }
    }
}
