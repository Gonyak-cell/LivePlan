import XCTest
@testable import AppCore

/// UpdateProjectUseCase 테스트
/// - testing.md: 규칙 변경 시 테스트 업데이트 준수
/// - data-model.md A1: Project 제약 조건 검증
final class UpdateProjectUseCaseTests: XCTestCase {

    private var projectRepository: MockProjectRepository!
    private var sut: UpdateProjectUseCase!

    override func setUp() {
        super.setUp()
        projectRepository = MockProjectRepository()
        sut = UpdateProjectUseCase(projectRepository: projectRepository)
    }

    override func tearDown() {
        projectRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Project Not Found

    func testExecute_ProjectNotFound_ThrowsError() async throws {
        // Given: 존재하지 않는 프로젝트 ID

        // When/Then
        do {
            _ = try await sut.execute(projectId: "nonexistent", title: "New Title")
            XCTFail("Expected error")
        } catch let error as UpdateProjectError {
            XCTAssertEqual(error, .projectNotFound("nonexistent"))
        }
    }

    // MARK: - Inbox Protection

    func testExecute_InboxProject_ThrowsError() async throws {
        // Given: Inbox 프로젝트
        let inbox = Project.createInbox()
        try await projectRepository.save(inbox)

        // When/Then: Inbox 수정 시도
        do {
            _ = try await sut.execute(projectId: Project.inboxProjectId, title: "New Title")
            XCTFail("Expected error")
        } catch let error as UpdateProjectError {
            XCTAssertEqual(error, .cannotModifyInbox)
        }
    }

    // MARK: - Title Update

    func testExecute_UpdateTitle_Success() async throws {
        // Given
        let project = Project(title: "Original Title", startDate: Date())
        try await projectRepository.save(project)

        // When
        let updated = try await sut.execute(projectId: project.id, title: "New Title")

        // Then
        XCTAssertEqual(updated.title, "New Title")
        XCTAssertGreaterThan(updated.updatedAt, project.updatedAt)
    }

    func testExecute_TrimmedTitle() async throws {
        // Given
        let project = Project(title: "Original", startDate: Date())
        try await projectRepository.save(project)

        // When
        let updated = try await sut.execute(projectId: project.id, title: "  Trimmed Title  ")

        // Then
        XCTAssertEqual(updated.title, "Trimmed Title")
    }

    func testExecute_EmptyTitle_ThrowsError() async throws {
        // Given
        let project = Project(title: "Original", startDate: Date())
        try await projectRepository.save(project)

        // When/Then
        do {
            _ = try await sut.execute(projectId: project.id, title: "   ")
            XCTFail("Expected error")
        } catch let error as UpdateProjectError {
            XCTAssertEqual(error, .emptyTitle)
        }
    }

    // MARK: - Start Date Update

    func testExecute_UpdateStartDate_Success() async throws {
        // Given
        let originalStartDate = Date()
        let project = Project(title: "Project", startDate: originalStartDate)
        try await projectRepository.save(project)
        let newStartDate = Date().addingTimeInterval(-86400) // 하루 전

        // When
        let updated = try await sut.execute(projectId: project.id, startDate: newStartDate)

        // Then
        XCTAssertEqual(updated.startDate, newStartDate)
    }

    // MARK: - Due Date Update

    func testExecute_SetDueDate_Success() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)
        let newDueDate = Date().addingTimeInterval(86400) // 하루 후

        // When
        let updated = try await sut.execute(projectId: project.id, dueDate: .some(newDueDate))

        // Then
        XCTAssertEqual(updated.dueDate, newDueDate)
    }

    func testExecute_RemoveDueDate_Success() async throws {
        // Given
        let dueDate = Date().addingTimeInterval(86400)
        let project = Project(title: "Project", startDate: Date(), dueDate: dueDate)
        try await projectRepository.save(project)

        // When
        let updated = try await sut.execute(projectId: project.id, dueDate: .none)

        // Then
        XCTAssertNil(updated.dueDate)
    }

    // MARK: - Date Validation

    func testExecute_InvalidDateRange_ThrowsError() async throws {
        // Given
        let startDate = Date()
        let project = Project(title: "Project", startDate: startDate)
        try await projectRepository.save(project)
        let invalidDueDate = startDate.addingTimeInterval(-86400) // 시작일보다 이전

        // When/Then
        do {
            _ = try await sut.execute(projectId: project.id, dueDate: .some(invalidDueDate))
            XCTFail("Expected error")
        } catch let error as UpdateProjectError {
            XCTAssertEqual(error, .invalidDateRange)
        }
    }

    func testExecute_StartDateAfterExistingDueDate_ThrowsError() async throws {
        // Given
        let startDate = Date()
        let dueDate = startDate.addingTimeInterval(86400)
        let project = Project(title: "Project", startDate: startDate, dueDate: dueDate)
        try await projectRepository.save(project)
        let invalidStartDate = dueDate.addingTimeInterval(86400) // 마감일보다 이후

        // When/Then
        do {
            _ = try await sut.execute(projectId: project.id, startDate: invalidStartDate)
            XCTFail("Expected error")
        } catch let error as UpdateProjectError {
            XCTAssertEqual(error, .invalidDateRange)
        }
    }

    func testExecute_UpdateBothDates_Valid_Success() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)
        let newStartDate = Date().addingTimeInterval(86400)
        let newDueDate = newStartDate.addingTimeInterval(86400)

        // When
        let updated = try await sut.execute(
            projectId: project.id,
            startDate: newStartDate,
            dueDate: .some(newDueDate)
        )

        // Then
        XCTAssertEqual(updated.startDate, newStartDate)
        XCTAssertEqual(updated.dueDate, newDueDate)
    }

    // MARK: - Status Update

    func testExecute_UpdateStatus_Success() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date(), status: .active)
        try await projectRepository.save(project)

        // When
        let updated = try await sut.execute(projectId: project.id, status: .archived)

        // Then
        XCTAssertEqual(updated.status, .archived)
    }

    func testExecute_CompleteProject_Success() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date(), status: .active)
        try await projectRepository.save(project)

        // When
        let updated = try await sut.execute(projectId: project.id, status: .completed)

        // Then
        XCTAssertEqual(updated.status, .completed)
    }

    func testExecute_ReactivateProject_Success() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date(), status: .archived)
        try await projectRepository.save(project)

        // When
        let updated = try await sut.execute(projectId: project.id, status: .active)

        // Then
        XCTAssertEqual(updated.status, .active)
    }

    // MARK: - Note Update

    func testExecute_SetNote_Success() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let updated = try await sut.execute(projectId: project.id, note: .some("New note"))

        // Then
        XCTAssertEqual(updated.note, "New note")
    }

    func testExecute_RemoveNote_Success() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date(), note: "Old note")
        try await projectRepository.save(project)

        // When
        let updated = try await sut.execute(projectId: project.id, note: .none)

        // Then
        XCTAssertNil(updated.note)
    }

    func testExecute_UpdateNote_Success() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date(), note: "Old note")
        try await projectRepository.save(project)

        // When
        let updated = try await sut.execute(projectId: project.id, note: .some("Updated note"))

        // Then
        XCTAssertEqual(updated.note, "Updated note")
    }

    // MARK: - Multiple Updates

    func testExecute_MultipleUpdates_Success() async throws {
        // Given
        let project = Project(title: "Original", startDate: Date(), status: .active)
        try await projectRepository.save(project)
        let newStartDate = Date().addingTimeInterval(86400)
        let newDueDate = newStartDate.addingTimeInterval(86400 * 7)

        // When
        let updated = try await sut.execute(
            projectId: project.id,
            title: "Updated Title",
            startDate: newStartDate,
            dueDate: .some(newDueDate),
            status: .archived,
            note: .some("Project note")
        )

        // Then
        XCTAssertEqual(updated.title, "Updated Title")
        XCTAssertEqual(updated.startDate, newStartDate)
        XCTAssertEqual(updated.dueDate, newDueDate)
        XCTAssertEqual(updated.status, .archived)
        XCTAssertEqual(updated.note, "Project note")
    }

    // MARK: - No Changes

    func testExecute_NoChanges_UpdatesTimestamp() async throws {
        // Given
        let originalUpdatedAt = Date().addingTimeInterval(-100)
        let project = Project(
            title: "Project",
            startDate: Date(),
            updatedAt: originalUpdatedAt
        )
        try await projectRepository.save(project)

        // When: 아무 변경 없이 호출
        let updated = try await sut.execute(projectId: project.id)

        // Then: updatedAt만 갱신됨
        XCTAssertEqual(updated.title, "Project")
        XCTAssertGreaterThan(updated.updatedAt, originalUpdatedAt)
    }

    // MARK: - Repository Persistence

    func testExecute_SavesUpdatedProject() async throws {
        // Given
        let project = Project(title: "Original", startDate: Date())
        try await projectRepository.save(project)

        // When
        _ = try await sut.execute(projectId: project.id, title: "Updated")

        // Then: 저장소에 반영 확인
        let saved = try await projectRepository.load(id: project.id)
        XCTAssertEqual(saved?.title, "Updated")
    }
}

// MARK: - Mock Repository

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
