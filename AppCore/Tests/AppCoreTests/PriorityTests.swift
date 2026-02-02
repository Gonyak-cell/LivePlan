import XCTest
@testable import AppCore

/// Priority 테스트
/// - data-model.md A4 준수: P1~P4, 기본값 P4
final class PriorityTests: XCTestCase {

    // MARK: - Default Value

    func testDefaultPriority_IsP4() {
        XCTAssertEqual(Priority.defaultPriority, .p4)
    }

    // MARK: - Raw Values

    func testRawValues() {
        XCTAssertEqual(Priority.p1.rawValue, 1)
        XCTAssertEqual(Priority.p2.rawValue, 2)
        XCTAssertEqual(Priority.p3.rawValue, 3)
        XCTAssertEqual(Priority.p4.rawValue, 4)
    }

    // MARK: - Comparable

    func testComparable_P1IsHighest() {
        XCTAssertTrue(Priority.p1 < Priority.p2)
        XCTAssertTrue(Priority.p1 < Priority.p3)
        XCTAssertTrue(Priority.p1 < Priority.p4)
    }

    func testComparable_SortOrder() {
        let unsorted: [Priority] = [.p4, .p2, .p1, .p3]
        let sorted = unsorted.sorted()

        XCTAssertEqual(sorted, [.p1, .p2, .p3, .p4])
    }

    func testComparable_Equal() {
        XCTAssertFalse(Priority.p2 < Priority.p2)
        XCTAssertTrue(Priority.p2 <= Priority.p2)
        XCTAssertTrue(Priority.p2 >= Priority.p2)
    }

    // MARK: - Parsing (QuickAdd)

    func testParsing_ValidLowercase() {
        XCTAssertEqual(Priority(parsing: "p1"), .p1)
        XCTAssertEqual(Priority(parsing: "p2"), .p2)
        XCTAssertEqual(Priority(parsing: "p3"), .p3)
        XCTAssertEqual(Priority(parsing: "p4"), .p4)
    }

    func testParsing_ValidUppercase() {
        XCTAssertEqual(Priority(parsing: "P1"), .p1)
        XCTAssertEqual(Priority(parsing: "P2"), .p2)
        XCTAssertEqual(Priority(parsing: "P3"), .p3)
        XCTAssertEqual(Priority(parsing: "P4"), .p4)
    }

    func testParsing_WithWhitespace() {
        XCTAssertEqual(Priority(parsing: " p1 "), .p1)
        XCTAssertEqual(Priority(parsing: "  P2  "), .p2)
    }

    func testParsing_Invalid() {
        XCTAssertNil(Priority(parsing: "p0"))
        XCTAssertNil(Priority(parsing: "p5"))
        XCTAssertNil(Priority(parsing: "priority1"))
        XCTAssertNil(Priority(parsing: "high"))
        XCTAssertNil(Priority(parsing: ""))
    }

    // MARK: - Codable

    func testCodable_RoundTrip() throws {
        let original = Priority.p2
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Priority.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testCodable_AllCases() throws {
        for priority in Priority.allCases {
            let data = try JSONEncoder().encode(priority)
            let decoded = try JSONDecoder().decode(Priority.self, from: data)
            XCTAssertEqual(decoded, priority)
        }
    }

    // MARK: - Labels

    func testLabel() {
        XCTAssertEqual(Priority.p1.label, "P1")
        XCTAssertEqual(Priority.p2.label, "P2")
        XCTAssertEqual(Priority.p3.label, "P3")
        XCTAssertEqual(Priority.p4.label, "P4")
    }

    func testDescriptionKR() {
        XCTAssertEqual(Priority.p1.descriptionKR, "가장 높음")
        XCTAssertEqual(Priority.p4.descriptionKR, "낮음")
    }

    func testDescriptionEN() {
        XCTAssertEqual(Priority.p1.descriptionEN, "Highest")
        XCTAssertEqual(Priority.p4.descriptionEN, "Low")
    }

    // MARK: - CaseIterable

    func testCaseIterable_Count() {
        XCTAssertEqual(Priority.allCases.count, 4)
    }
}
