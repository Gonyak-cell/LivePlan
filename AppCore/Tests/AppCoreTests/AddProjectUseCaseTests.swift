import XCTest
@testable import AppCore

/// AddProjectUseCase 테스트
/// - testing.md A1: AppCore 단위 테스트 필수
/// - data-model.md A1: Project 필드 검증
final class AddProjectUseCaseTests: XCTestCase {

    private var projectRepository: MockProjectRepository!
    private var sut: AddProjectUseCase!

    override func setUp() {
        super.setUp()
        projectRepository = MockProjectRepository()
        sut = AddProjectUseCase(projectRepository: projectRepository)
    }

    override func tearDown() {
        projectRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Success Cases

    func testExecute_BasicProject_Success() async throws {
        // Given
        let startDate = Date()

        // When
        let project = try await sut.execute(
            title: "New Project",
            startDate: startDate
        )

        // Then
        XCTAssertEqual(project.title, "New Project")
        XCTAssertEqual(project.startDate, startDate)
        XCTAssertNil(project.dueDate)
        XCTAssertEqual(project.status, .active)
    }

    func testExecute_WithDueDate_Success() async throws {
        // Given
        let startDate = Date()
        let dueDate = startDate.addingTimeInterval(86400 * 7) // 7일 후

        // When
        let project = try await sut.execute(
            title: "Project with Due Date",
            startDate: startDate,
            dueDate: dueDate
        )

        // Then
        XCTAssertEqual(project.title, "Project with Due Date")
        XCTAssertEqual(project.startDate, startDate)
        XCTAssertEqual(project.dueDate, dueDate)
    }

    func testExecute_DueDateEqualsStartDate_Success() async throws {
        // Given: dueDate == startDate (허용)
        let date = Date()

        // When
        let project = try await sut.execute(
            title: "Same Day Project",
            startDate: date,
            dueDate: date
        )

        // Then
        XCTAssertEqual(project.startDate, project.dueDate)
    }

    func testExecute_TrimmedTitle() async throws {
        // Given
        let startDate = Date()

        // When
        let project = try await sut.execute(
            title: "  Trimmed Title  ",
            startDate: startDate
        )

        // Then
        XCTAssertEqual(project.title, "Trimmed Title")
    }

    // MARK: - Error Cases

    func testExecute_EmptyTitle_ThrowsError() async throws {
        // Given
        let startDate = Date()

        // When/Then
        do {
            _ = try await sut.execute(title: "", startDate: startDate)
            XCTFail("Expected error")
        } catch let error as AddProjectError {
            XCTAssertEqual(error, .emptyTitle)
        }
    }

    func testExecute_WhitespaceOnlyTitle_ThrowsError() async throws {
        // Given
        let startDate = Date()

        // When/Then
        do {
            _ = try await sut.execute(title: "   ", startDate: startDate)
            XCTFail("Expected error")
        } catch let error as AddProjectError {
            XCTAssertEqual(error, .emptyTitle)
        }
    }

    func testExecute_DueDateBeforeStartDate_ThrowsError() async throws {
        // Given: dueDate < startDate (금지)
        let startDate = Date()
        let dueDate = startDate.addingTimeInterval(-86400) // 하루 전

        // When/Then
        do {
            _ = try await sut.execute(
                title: "Invalid Project",
                startDate: startDate,
                dueDate: dueDate
            )
            XCTFail("Expected error")
        } catch let error as AddProjectError {
            XCTAssertEqual(error, .invalidDateRange)
        }
    }

    // MARK: - Persistence

    func testExecute_ProjectIsSaved() async throws {
        // Given
        let startDate = Date()

        // When
        let project = try await sut.execute(
            title: "Saved Project",
            startDate: startDate
        )

        // Then: 저장소에 저장되었는지 확인
        let savedProject = try await projectRepository.load(id: project.id)
        XCTAssertNotNil(savedProject)
        XCTAssertEqual(savedProject?.title, "Saved Project")
    }

    func testExecute_MultipleProjects_AllSaved() async throws {
        // Given
        let startDate = Date()

        // When
        let project1 = try await sut.execute(title: "Project 1", startDate: startDate)
        let project2 = try await sut.execute(title: "Project 2", startDate: startDate)
        let project3 = try await sut.execute(title: "Project 3", startDate: startDate)

        // Then
        let allProjects = try await projectRepository.loadAll()
        XCTAssertEqual(allProjects.count, 3)
        XCTAssertTrue(allProjects.contains { $0.id == project1.id })
        XCTAssertTrue(allProjects.contains { $0.id == project2.id })
        XCTAssertTrue(allProjects.contains { $0.id == project3.id })
    }

    // MARK: - Error Description

    func testAddProjectError_ErrorDescriptions() {
        let emptyTitleError = AddProjectError.emptyTitle
        XCTAssertEqual(emptyTitleError.errorDescription, "Project title cannot be empty")

        let invalidDateRangeError = AddProjectError.invalidDateRange
        XCTAssertEqual(invalidDateRangeError.errorDescription, "Due date must be on or after start date")
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
}
