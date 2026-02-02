import XCTest
@testable import AppCore

/// Project 테스트
/// - data-model.md A1 준수
/// - Phase 2: note 필드 추가
final class ProjectTests: XCTestCase {

    // MARK: - Creation

    func testProject_BasicCreation() {
        let project = Project(title: "My Project", startDate: Date())

        XCTAssertFalse(project.id.isEmpty)
        XCTAssertEqual(project.title, "My Project")
        XCTAssertEqual(project.status, .active)
        XCTAssertNil(project.dueDate)
        XCTAssertNil(project.note)
    }

    func testProject_WithNote() {
        let project = Project(
            title: "Project",
            startDate: Date(),
            note: "This is a project note"
        )

        XCTAssertEqual(project.note, "This is a project note")
        XCTAssertTrue(project.hasNote)
    }

    // MARK: - Note Convenience

    func testHasNote_WithContent() {
        let project = Project(title: "P", startDate: Date(), note: "Some content")
        XCTAssertTrue(project.hasNote)
    }

    func testHasNote_Empty() {
        let project = Project(title: "P", startDate: Date(), note: "")
        XCTAssertFalse(project.hasNote)
    }

    func testHasNote_WhitespaceOnly() {
        let project = Project(title: "P", startDate: Date(), note: "   \n  ")
        XCTAssertFalse(project.hasNote)
    }

    func testHasNote_Nil() {
        let project = Project(title: "P", startDate: Date())
        XCTAssertFalse(project.hasNote)
    }

    // MARK: - Validation

    func testValidation_ValidDates() {
        let start = Date()
        let due = start.addingTimeInterval(86400) // 1 day later

        let project = Project(title: "P", startDate: start, dueDate: due)

        XCTAssertTrue(project.isValid)
    }

    func testValidation_SameDates() {
        let date = Date()

        let project = Project(title: "P", startDate: date, dueDate: date)

        XCTAssertTrue(project.isValid)
    }

    func testValidation_InvalidDates() {
        let start = Date()
        let due = start.addingTimeInterval(-86400) // 1 day before

        let project = Project(title: "P", startDate: start, dueDate: due)

        XCTAssertFalse(project.isValid)
    }

    func testValidation_NoDueDate() {
        let project = Project(title: "P", startDate: Date())

        XCTAssertTrue(project.isValid)
    }

    // MARK: - ProjectStatus

    func testProjectStatus_IsActive() {
        XCTAssertTrue(ProjectStatus.active.isActive)
        XCTAssertFalse(ProjectStatus.archived.isActive)
        XCTAssertFalse(ProjectStatus.completed.isActive)
    }

    func testProjectStatus_IsExcludedFromLockScreen() {
        XCTAssertFalse(ProjectStatus.active.isExcludedFromLockScreen)
        XCTAssertTrue(ProjectStatus.archived.isExcludedFromLockScreen)
        XCTAssertTrue(ProjectStatus.completed.isExcludedFromLockScreen)
    }

    func testProjectStatus_Descriptions() {
        XCTAssertEqual(ProjectStatus.active.descriptionKR, "활성")
        XCTAssertEqual(ProjectStatus.archived.descriptionKR, "보관됨")
        XCTAssertEqual(ProjectStatus.completed.descriptionKR, "완료됨")

        XCTAssertEqual(ProjectStatus.active.descriptionEN, "Active")
        XCTAssertEqual(ProjectStatus.archived.descriptionEN, "Archived")
        XCTAssertEqual(ProjectStatus.completed.descriptionEN, "Completed")
    }

    // MARK: - Inbox

    func testInboxProject() {
        let inbox = Project.createInbox()

        XCTAssertEqual(inbox.id, Project.inboxProjectId)
        XCTAssertEqual(inbox.title, "Inbox")
        XCTAssertTrue(inbox.isInbox)
    }

    func testIsInbox_Regular() {
        let project = Project(title: "Regular", startDate: Date())

        XCTAssertFalse(project.isInbox)
    }

    // MARK: - Codable

    func testCodable_RoundTrip() throws {
        let project = Project(
            id: "p1",
            title: "Test Project",
            startDate: Date(),
            dueDate: Date().addingTimeInterval(86400),
            status: .active,
            note: "Project notes here"
        )

        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(Project.self, from: data)

        XCTAssertEqual(decoded.id, project.id)
        XCTAssertEqual(decoded.title, project.title)
        XCTAssertEqual(decoded.status, project.status)
        XCTAssertEqual(decoded.note, project.note)
    }

    func testCodable_Phase1Migration() throws {
        // Phase 1 형식 JSON (note 필드 없음)
        let phase1JSON = """
        {
            "id": "p1",
            "title": "Old Project",
            "startDate": 0,
            "status": "active",
            "createdAt": 0,
            "updatedAt": 0
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Project.self, from: phase1JSON)

        XCTAssertEqual(decoded.id, "p1")
        XCTAssertEqual(decoded.title, "Old Project")
        XCTAssertNil(decoded.note) // 기본값
        XCTAssertFalse(decoded.hasNote)
    }

    // MARK: - Equatable

    func testEquatable() {
        let p1 = Project(id: "p1", title: "Project", startDate: Date())
        let p2 = Project(id: "p1", title: "Project", startDate: Date())
        let p3 = Project(id: "p2", title: "Project", startDate: Date())

        XCTAssertEqual(p1, p2)
        XCTAssertNotEqual(p1, p3)
    }
}
