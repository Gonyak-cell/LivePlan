import XCTest
@testable import AppCore

/// ProjectViewType 테스트
/// - data-model.md A8 / product-decisions.md 1.2 준수
final class ProjectViewTypeTests: XCTestCase {

    // MARK: - Default Value

    func testDefaultViewType_IsList() {
        XCTAssertEqual(ProjectViewType.defaultViewType, .list)
    }

    // MARK: - CaseIterable

    func testCaseIterable_Count() {
        XCTAssertEqual(ProjectViewType.allCases.count, 3)
    }

    func testCaseIterable_AllCases() {
        let allCases = ProjectViewType.allCases
        XCTAssertTrue(allCases.contains(.list))
        XCTAssertTrue(allCases.contains(.board))
        XCTAssertTrue(allCases.contains(.calendar))
    }

    // MARK: - Codable

    func testCodable_RoundTrip() throws {
        for viewType in ProjectViewType.allCases {
            let data = try JSONEncoder().encode(viewType)
            let decoded = try JSONDecoder().decode(ProjectViewType.self, from: data)
            XCTAssertEqual(decoded, viewType)
        }
    }

    func testCodable_RawValueEncoding() throws {
        let data = try JSONEncoder().encode(ProjectViewType.board)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertEqual(jsonString, "\"board\"")
    }

    // MARK: - Labels

    func testLabelKR() {
        XCTAssertEqual(ProjectViewType.list.labelKR, "리스트")
        XCTAssertEqual(ProjectViewType.board.labelKR, "보드")
        XCTAssertEqual(ProjectViewType.calendar.labelKR, "캘린더")
    }

    func testLabelEN() {
        XCTAssertEqual(ProjectViewType.list.labelEN, "List")
        XCTAssertEqual(ProjectViewType.board.labelEN, "Board")
        XCTAssertEqual(ProjectViewType.calendar.labelEN, "Calendar")
    }

    // MARK: - Icons

    func testIconName() {
        XCTAssertEqual(ProjectViewType.list.iconName, "list.bullet")
        XCTAssertEqual(ProjectViewType.board.iconName, "rectangle.split.3x1")
        XCTAssertEqual(ProjectViewType.calendar.iconName, "calendar")
    }
}
