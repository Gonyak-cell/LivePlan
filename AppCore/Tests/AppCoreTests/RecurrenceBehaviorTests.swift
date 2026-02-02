import XCTest
@testable import AppCore

/// RecurrenceBehavior 테스트
/// - data-model.md A4, product-decisions.md 3.3 준수
final class RecurrenceBehaviorTests: XCTestCase {

    // MARK: - Default Values

    func testDefaultForDailyRecurring_IsHabitReset() {
        // product-decisions.md 3.3: dailyRecurring은 Habit reset 유지
        XCTAssertEqual(RecurrenceBehavior.defaultForDailyRecurring, .habitReset)
    }

    func testDefaultForRecurrenceRule_IsRollover() {
        // product-decisions.md 3.3: 반복 규칙 확장 태스크는 Rollover 기본
        XCTAssertEqual(RecurrenceBehavior.defaultForRecurrenceRule, .rollover)
    }

    // MARK: - Raw Values

    func testRawValues() {
        XCTAssertEqual(RecurrenceBehavior.habitReset.rawValue, "habitReset")
        XCTAssertEqual(RecurrenceBehavior.rollover.rawValue, "rollover")
    }

    // MARK: - Completion Semantics

    func testHabitReset_DoesNotCarryOver() {
        let behavior = RecurrenceBehavior.habitReset

        XCTAssertFalse(behavior.carriesOverIncomplete)
        XCTAssertFalse(behavior.canBeOverdue)
    }

    func testRollover_CarriesOver() {
        let behavior = RecurrenceBehavior.rollover

        XCTAssertTrue(behavior.carriesOverIncomplete)
        XCTAssertTrue(behavior.canBeOverdue)
    }

    // MARK: - Labels

    func testLabelKR() {
        XCTAssertEqual(RecurrenceBehavior.habitReset.labelKR, "습관 모드")
        XCTAssertEqual(RecurrenceBehavior.rollover.labelKR, "업무 모드")
    }

    func testLabelEN() {
        XCTAssertEqual(RecurrenceBehavior.habitReset.labelEN, "Habit Mode")
        XCTAssertEqual(RecurrenceBehavior.rollover.labelEN, "Work Mode")
    }

    func testDescriptionKR() {
        XCTAssertFalse(RecurrenceBehavior.habitReset.descriptionKR.isEmpty)
        XCTAssertFalse(RecurrenceBehavior.rollover.descriptionKR.isEmpty)
    }

    func testDescriptionEN() {
        XCTAssertFalse(RecurrenceBehavior.habitReset.descriptionEN.isEmpty)
        XCTAssertFalse(RecurrenceBehavior.rollover.descriptionEN.isEmpty)
    }

    // MARK: - Codable

    func testCodable_RoundTrip() throws {
        for behavior in RecurrenceBehavior.allCases {
            let data = try JSONEncoder().encode(behavior)
            let decoded = try JSONDecoder().decode(RecurrenceBehavior.self, from: data)
            XCTAssertEqual(decoded, behavior)
        }
    }

    func testCodable_JSONFormat() throws {
        let behavior = RecurrenceBehavior.habitReset
        let data = try JSONEncoder().encode(behavior)
        let json = String(data: data, encoding: .utf8)

        XCTAssertEqual(json, "\"habitReset\"")
    }

    // MARK: - CaseIterable

    func testCaseIterable_Count() {
        XCTAssertEqual(RecurrenceBehavior.allCases.count, 2)
    }
}
