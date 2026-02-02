import XCTest
@testable import AppCore

/// Section 테스트
/// - data-model.md A2 준수
final class SectionTests: XCTestCase {

    // MARK: - Creation

    func testSection_Creation() {
        let section = Section(
            projectId: "project-1",
            title: "To Do"
        )

        XCTAssertFalse(section.id.isEmpty)
        XCTAssertEqual(section.projectId, "project-1")
        XCTAssertEqual(section.title, "To Do")
        XCTAssertEqual(section.orderIndex, 0)
    }

    func testSection_WithOrderIndex() {
        let section = Section(
            projectId: "project-1",
            title: "In Progress",
            orderIndex: 1
        )

        XCTAssertEqual(section.orderIndex, 1)
    }

    // MARK: - Sorting (Comparable)

    func testComparable_ByOrderIndex() {
        let section1 = Section(projectId: "p1", title: "First", orderIndex: 0)
        let section2 = Section(projectId: "p1", title: "Second", orderIndex: 1)
        let section3 = Section(projectId: "p1", title: "Third", orderIndex: 2)

        XCTAssertTrue(section1 < section2)
        XCTAssertTrue(section2 < section3)

        let unsorted = [section3, section1, section2]
        let sorted = unsorted.sorted()

        XCTAssertEqual(sorted.map(\.title), ["First", "Second", "Third"])
    }

    func testComparable_SameOrderIndex_ByCreatedAt() {
        let earlier = Date(timeIntervalSince1970: 1000)
        let later = Date(timeIntervalSince1970: 2000)

        let section1 = Section(projectId: "p1", title: "A", orderIndex: 0, createdAt: earlier)
        let section2 = Section(projectId: "p1", title: "B", orderIndex: 0, createdAt: later)

        XCTAssertTrue(section1 < section2)
    }

    // MARK: - Convenience

    func testBelongsTo() {
        let section = Section(projectId: "project-1", title: "Section")

        XCTAssertTrue(section.belongsTo(projectId: "project-1"))
        XCTAssertFalse(section.belongsTo(projectId: "project-2"))
    }

    // MARK: - Array Extensions

    func testForProject() {
        let sections = [
            Section(projectId: "p1", title: "S1"),
            Section(projectId: "p2", title: "S2"),
            Section(projectId: "p1", title: "S3")
        ]

        let p1Sections = sections.forProject("p1")

        XCTAssertEqual(p1Sections.count, 2)
        XCTAssertTrue(p1Sections.allSatisfy { $0.projectId == "p1" })
    }

    func testSortedByOrder() {
        let sections = [
            Section(projectId: "p1", title: "Third", orderIndex: 2),
            Section(projectId: "p1", title: "First", orderIndex: 0),
            Section(projectId: "p1", title: "Second", orderIndex: 1)
        ]

        let sorted = sections.sortedByOrder()

        XCTAssertEqual(sorted.map(\.title), ["First", "Second", "Third"])
    }

    func testNextOrderIndex() {
        let sections = [
            Section(projectId: "p1", title: "S1", orderIndex: 0),
            Section(projectId: "p1", title: "S2", orderIndex: 1),
            Section(projectId: "p2", title: "S3", orderIndex: 5)
        ]

        XCTAssertEqual(sections.nextOrderIndex(for: "p1"), 2)
        XCTAssertEqual(sections.nextOrderIndex(for: "p2"), 6)
        XCTAssertEqual(sections.nextOrderIndex(for: "p3"), 0) // 없는 프로젝트
    }

    func testNextOrderIndex_Empty() {
        let sections: [Section] = []

        XCTAssertEqual(sections.nextOrderIndex(for: "p1"), 0)
    }

    // MARK: - Codable

    func testCodable_RoundTrip() throws {
        let section = Section(
            id: "section-1",
            projectId: "project-1",
            title: "My Section",
            orderIndex: 3
        )

        let data = try JSONEncoder().encode(section)
        let decoded = try JSONDecoder().decode(Section.self, from: data)

        XCTAssertEqual(decoded.id, section.id)
        XCTAssertEqual(decoded.projectId, section.projectId)
        XCTAssertEqual(decoded.title, section.title)
        XCTAssertEqual(decoded.orderIndex, section.orderIndex)
    }

    // MARK: - Equatable

    func testEquatable() {
        let section1 = Section(id: "s1", projectId: "p1", title: "Section")
        let section2 = Section(id: "s1", projectId: "p1", title: "Section")
        let section3 = Section(id: "s2", projectId: "p1", title: "Section")

        XCTAssertEqual(section1, section2)
        XCTAssertNotEqual(section1, section3)
    }
}
