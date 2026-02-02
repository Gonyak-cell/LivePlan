import XCTest
@testable import AppCore

/// DateKey 테스트
/// - testing.md B4, B5 준수
final class DateKeyTests: XCTestCase {

    // MARK: - B4: 자정 경계 (23:59 / 00:01)

    func testMidnightBoundary_23_59_to_00_01() {
        // Given: 동일한 날의 23:59와 다음 날의 00:01
        let calendar = Calendar.current
        var components1 = DateComponents()
        components1.year = 2026
        components1.month = 2
        components1.day = 1
        components1.hour = 23
        components1.minute = 59
        let date1 = calendar.date(from: components1)!

        var components2 = DateComponents()
        components2.year = 2026
        components2.month = 2
        components2.day = 2
        components2.hour = 0
        components2.minute = 1
        let date2 = calendar.date(from: components2)!

        // When
        let dateKey1 = DateKey.from(date1)
        let dateKey2 = DateKey.from(date2)

        // Then: dateKey가 다름
        XCTAssertNotEqual(dateKey1, dateKey2)
        XCTAssertEqual(dateKey1.value, "2026-02-01")
        XCTAssertEqual(dateKey2.value, "2026-02-02")
    }

    func testMidnightBoundary_ExactMidnight() {
        // Given: 정확히 자정 (00:00:00)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 2
        components.hour = 0
        components.minute = 0
        components.second = 0
        let midnight = calendar.date(from: components)!

        // When
        let dateKey = DateKey.from(midnight)

        // Then: 새 날짜에 속함
        XCTAssertEqual(dateKey.value, "2026-02-02")
    }

    // MARK: - B5: 타임존 변경

    func testTimeZone_DifferentZones() {
        // Given: 동일한 절대 시각, 다른 타임존
        let date = Date(timeIntervalSince1970: 1738368000) // 2025-02-01 00:00:00 UTC

        let utc = TimeZone(identifier: "UTC")!
        let kst = TimeZone(identifier: "Asia/Seoul")! // UTC+9

        // When
        let dateKeyUTC = DateKey.from(date, timeZone: utc)
        let dateKeyKST = DateKey.from(date, timeZone: kst)

        // Then: 다를 수 있음 (타임존 차이)
        // UTC: 2025-02-01 00:00
        // KST: 2025-02-01 09:00
        XCTAssertEqual(dateKeyUTC.value, "2025-02-01")
        XCTAssertEqual(dateKeyKST.value, "2025-02-01")
    }

    func testTimeZone_DateLineChange() {
        // Given: UTC 기준 2025-01-31 23:00 -> KST 기준 2025-02-01 08:00
        let calendar = Calendar(identifier: .gregorian)
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!

        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 31
        components.hour = 23
        components.minute = 0
        let date = utcCalendar.date(from: components)!

        let utc = TimeZone(identifier: "UTC")!
        let kst = TimeZone(identifier: "Asia/Seoul")!

        // When
        let dateKeyUTC = DateKey.from(date, timeZone: utc)
        let dateKeyKST = DateKey.from(date, timeZone: kst)

        // Then: 타임존에 따라 날짜가 다름
        XCTAssertEqual(dateKeyUTC.value, "2025-01-31")
        XCTAssertEqual(dateKeyKST.value, "2025-02-01")
    }

    // MARK: - Basic Operations

    func testToday() {
        let today = DateKey.today()
        XCTAssertFalse(today.value.isEmpty)
        XCTAssertTrue(today.value.count == 10) // YYYY-MM-DD
    }

    func testParse_Valid() {
        let dateKey = DateKey.parse("2025-02-01")
        XCTAssertNotNil(dateKey)
        XCTAssertEqual(dateKey?.value, "2025-02-01")
    }

    func testParse_Invalid() {
        XCTAssertNil(DateKey.parse("2025-2-1"))
        XCTAssertNil(DateKey.parse("20250201"))
        XCTAssertNil(DateKey.parse("invalid"))
    }

    func testNextDay() {
        let dateKey = DateKey.parse("2025-02-28")!
        let nextDay = dateKey.nextDay()

        XCTAssertNotNil(nextDay)
        XCTAssertEqual(nextDay?.value, "2025-03-01")
    }

    func testComparable() {
        let day1: DateKey = "2025-02-01"
        let day2: DateKey = "2025-02-02"

        XCTAssertTrue(day1 < day2)
        XCTAssertFalse(day2 < day1)
        XCTAssertTrue(day1 <= day2)
    }
}
