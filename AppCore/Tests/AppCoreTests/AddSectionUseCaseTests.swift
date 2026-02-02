import XCTest
@testable import AppCore

/// AddSectionUseCase 테스트
/// - testing.md A1: AppCore 단위 테스트 필수
/// - data-model.md A2: Section은 프로젝트 내부 그룹
final class AddSectionUseCaseTests: XCTestCase {

    private var sectionRepository: MockSectionRepository!
    private var projectRepository: MockProjectRepository!
    private var sut: AddSectionUseCase!

    override func setUp() {
        super.setUp()
        sectionRepository = MockSectionRepository()
        projectRepository = MockProjectRepository()
        sut = AddSectionUseCase(
            sectionRepository: sectionRepository,
            projectRepository: projectRepository
        )
    }

    override func tearDown() {
        sectionRepository = nil
        projectRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Section Creation

    func testExecute_BasicSection_Success() async throws {
        // Given
        let project = Project(title: "Test Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let section = try await sut.execute(
            title: "New Section",
            projectId: project.id
        )

        // Then
        XCTAssertEqual(section.title, "New Section")
        XCTAssertEqual(section.projectId, project.id)
        XCTAssertEqual(section.orderIndex, 0)
    }

    func testExecute_TrimmedTitle() async throws {
        // Given
        let project = Project(title: "Test Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let section = try await sut.execute(
            title: "  Trimmed Title  ",
            projectId: project.id
        )

        // Then
        XCTAssertEqual(section.title, "Trimmed Title")
    }

    // MARK: - Error Cases

    func testExecute_EmptyTitle_ThrowsError() async throws {
        // Given
        let project = Project(title: "Test Project", startDate: Date())
        try await projectRepository.save(project)

        // When/Then
        do {
            _ = try await sut.execute(title: "   ", projectId: project.id)
            XCTFail("Expected error")
        } catch let error as AddSectionError {
            XCTAssertEqual(error, .emptyTitle)
        }
    }

    func testExecute_ProjectNotFound_ThrowsError() async throws {
        // When/Then
        do {
            _ = try await sut.execute(title: "Section", projectId: "nonexistent")
            XCTFail("Expected error")
        } catch let error as AddSectionError {
            XCTAssertEqual(error, .projectNotFound)
        }
    }

    func testExecute_ArchivedProject_ThrowsError() async throws {
        // Given: archived 상태의 프로젝트
        var project = Project(title: "Archived Project", startDate: Date())
        project.status = .archived
        try await projectRepository.save(project)

        // When/Then
        do {
            _ = try await sut.execute(title: "Section", projectId: project.id)
            XCTFail("Expected error")
        } catch let error as AddSectionError {
            XCTAssertEqual(error, .projectNotActive)
        }
    }

    func testExecute_CompletedProject_ThrowsError() async throws {
        // Given: completed 상태의 프로젝트
        var project = Project(title: "Completed Project", startDate: Date())
        project.status = .completed
        try await projectRepository.save(project)

        // When/Then
        do {
            _ = try await sut.execute(title: "Section", projectId: project.id)
            XCTFail("Expected error")
        } catch let error as AddSectionError {
            XCTAssertEqual(error, .projectNotActive)
        }
    }

    // MARK: - Order Index

    func testExecute_AutoOrderIndex_FirstSection() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When: 첫 번째 섹션
        let section = try await sut.execute(
            title: "First Section",
            projectId: project.id
        )

        // Then: orderIndex = 0
        XCTAssertEqual(section.orderIndex, 0)
    }

    func testExecute_AutoOrderIndex_SecondSection() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // 첫 번째 섹션 생성
        _ = try await sut.execute(title: "First", projectId: project.id)

        // When: 두 번째 섹션
        let section = try await sut.execute(
            title: "Second Section",
            projectId: project.id
        )

        // Then: orderIndex = 1
        XCTAssertEqual(section.orderIndex, 1)
    }

    func testExecute_AutoOrderIndex_MultipleProjects() async throws {
        // Given: 두 개의 프로젝트
        let project1 = Project(title: "Project 1", startDate: Date())
        let project2 = Project(title: "Project 2", startDate: Date())
        try await projectRepository.save(project1)
        try await projectRepository.save(project2)

        // Project 1에 섹션 2개 추가
        _ = try await sut.execute(title: "P1 Section 1", projectId: project1.id)
        _ = try await sut.execute(title: "P1 Section 2", projectId: project1.id)

        // When: Project 2에 첫 번째 섹션
        let section = try await sut.execute(
            title: "P2 Section 1",
            projectId: project2.id
        )

        // Then: Project 2의 첫 번째이므로 orderIndex = 0
        XCTAssertEqual(section.orderIndex, 0)
    }

    func testExecute_CustomOrderIndex() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When: 명시적 orderIndex 지정
        let section = try await sut.execute(
            title: "Section",
            projectId: project.id,
            orderIndex: 5
        )

        // Then
        XCTAssertEqual(section.orderIndex, 5)
    }

    func testExecute_CustomOrderIndex_OverridesAuto() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)
        _ = try await sut.execute(title: "First", projectId: project.id) // orderIndex = 0

        // When: 자동 계산이면 1이겠지만, 명시적으로 10 지정
        let section = try await sut.execute(
            title: "Second",
            projectId: project.id,
            orderIndex: 10
        )

        // Then
        XCTAssertEqual(section.orderIndex, 10)
    }

    // MARK: - Persistence

    func testExecute_SectionIsSaved() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When
        let section = try await sut.execute(
            title: "Section",
            projectId: project.id
        )

        // Then: 저장소에 저장되었는지 확인
        let savedSection = try await sectionRepository.load(id: section.id)
        XCTAssertNotNil(savedSection)
        XCTAssertEqual(savedSection?.title, "Section")
        XCTAssertEqual(savedSection?.projectId, project.id)
    }

    func testExecute_MultipleSections_AllSaved() async throws {
        // Given
        let project = Project(title: "Project", startDate: Date())
        try await projectRepository.save(project)

        // When: 3개의 섹션 생성
        let section1 = try await sut.execute(title: "Section 1", projectId: project.id)
        let section2 = try await sut.execute(title: "Section 2", projectId: project.id)
        let section3 = try await sut.execute(title: "Section 3", projectId: project.id)

        // Then: 모두 저장됨
        let allSections = try await sectionRepository.loadByProject(projectId: project.id)
        XCTAssertEqual(allSections.count, 3)
        XCTAssertTrue(allSections.contains { $0.id == section1.id })
        XCTAssertTrue(allSections.contains { $0.id == section2.id })
        XCTAssertTrue(allSections.contains { $0.id == section3.id })
    }
}

// MARK: - Mock Repositories

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
