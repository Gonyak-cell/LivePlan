import XCTest
@testable import AppCore

/// RecurrenceRule 테스트
/// - data-model.md A5 준수
final class RecurrenceRuleTests: XCTestCase {

    // MARK: - RecurrenceKind

    func testRecurrenceKind_AllCases() {
        XCTAssertEqual(RecurrenceKind.allCases.count, 3)
        XCTAssertTrue(RecurrenceKind.allCases.contains(.daily))
        XCTAssertTrue(RecurrenceKind.allCases.contains(.weekly))
        XCTAssertTrue(RecurrenceKind.allCases.contains(.monthly))
    }

    // MARK: - Weekday

    func testWeekday_CalendarCompatibility() {
        // Calendar.component(.weekday) returns 1 for Sunday
        XCTAssertEqual(Weekday.sunday.calendarWeekday, 1)
        XCTAssertEqual(Weekday.monday.calendarWeekday, 2)
        XCTAssertEqual(Weekday.saturday.calendarWeekday, 7)
    }

    func testWeekday_InitFromCalendar() {
        XCTAssertEqual(Weekday(calendarWeekday: 1), .sunday)
        XCTAssertEqual(Weekday(calendarWeekday: 2), .monday)
        XCTAssertNil(Weekday(calendarWeekday: 0))
        XCTAssertNil(Weekday(calendarWeekday: 8))
    }

    func testWeekday_Comparable() {
        XCTAssertTrue(Weekday.sunday < Weekday.monday)
        XCTAssertTrue(Weekday.friday < Weekday.saturday)

        let unsorted: [Weekday] = [.friday, .monday, .wednesday]
        let sorted = unsorted.sorted()
        XCTAssertEqual(sorted, [.monday, .wednesday, .friday])
    }

    // MARK: - TimeOfDay

    func testTimeOfDay_Validation() {
        let time = TimeOfDay(hour: 25, minute: 70)
        XCTAssertEqual(time.hour, 23) // clamped
        XCTAssertEqual(time.minute, 59) // clamped
    }

    func testTimeOfDay_Formatted() {
        let time = TimeOfDay(hour: 14, minute: 30)
        XCTAssertEqual(time.formatted, "14:30")
        XCTAssertEqual(time.formatted12Hour, "2:30 PM")
        XCTAssertEqual(time.formattedKR, "오후 2:30")
    }

    func testTimeOfDay_Midnight() {
        let midnight = TimeOfDay(hour: 0, minute: 0)
        XCTAssertEqual(midnight.formatted12Hour, "12:00 AM")
        XCTAssertEqual(midnight.formattedKR, "오전 12:00")
    }

    func testTimeOfDay_Comparable() {
        let morning = TimeOfDay(hour: 9, minute: 0)
        let afternoon = TimeOfDay(hour: 14, minute: 30)
        let evening = TimeOfDay(hour: 14, minute: 45)

        XCTAssertTrue(morning < afternoon)
        XCTAssertTrue(afternoon < evening)
    }

    // MARK: - RecurrenceRule Creation

    func testDaily_Default() {
        let rule = RecurrenceRule.daily()

        XCTAssertEqual(rule.kind, .daily)
        XCTAssertEqual(rule.interval, 1)
        XCTAssertTrue(rule.weekdays.isEmpty)
        XCTAssertNil(rule.timeOfDay)
        XCTAssertTrue(rule.isValid)
    }

    func testWeekly_WithWeekdays() {
        let rule = RecurrenceRule.weekly(weekdays: [.monday, .wednesday, .friday])

        XCTAssertEqual(rule.kind, .weekly)
        XCTAssertEqual(rule.weekdays, [.monday, .wednesday, .friday])
        XCTAssertTrue(rule.isValid)
    }

    func testWeekdays_Preset() {
        let rule = RecurrenceRule.weekdays()

        XCTAssertEqual(rule.kind, .weekly)
        XCTAssertEqual(rule.weekdays.count, 5)
        XCTAssertTrue(rule.weekdays.contains(.monday))
        XCTAssertTrue(rule.weekdays.contains(.friday))
        XCTAssertFalse(rule.weekdays.contains(.sunday))
        XCTAssertFalse(rule.weekdays.contains(.saturday))
    }

    func testMonthly_Default() {
        let rule = RecurrenceRule.monthly()

        XCTAssertEqual(rule.kind, .monthly)
        XCTAssertEqual(rule.interval, 1)
        XCTAssertTrue(rule.isValid)
    }

    // MARK: - Validation

    func testValidation_InvalidInterval() {
        let rule = RecurrenceRule(kind: .daily, interval: 0)

        // interval은 init에서 max(1, interval)로 보정됨
        XCTAssertEqual(rule.interval, 1)
        XCTAssertTrue(rule.isValid)
    }

    func testValidation_WeeklyWithoutWeekdays() {
        let rule = RecurrenceRule(kind: .weekly, weekdays: [])

        XCTAssertFalse(rule.isValid)
        XCTAssertEqual(rule.validate(), .weeklyWithoutWeekdays)
    }

    func testValidation_WeeklyWithWeekdays() {
        let rule = RecurrenceRule(kind: .weekly, weekdays: [.monday])

        XCTAssertTrue(rule.isValid)
        XCTAssertNil(rule.validate())
    }

    // MARK: - Summary

    func testSummaryKR_Daily() {
        let rule = RecurrenceRule.daily()
        XCTAssertEqual(rule.summaryKR, "매일")
    }

    func testSummaryKR_EveryTwoDays() {
        let rule = RecurrenceRule.daily(interval: 2)
        XCTAssertEqual(rule.summaryKR, "2 일마다")
    }

    func testSummaryKR_Weekdays() {
        let rule = RecurrenceRule.weekdays()
        XCTAssertEqual(rule.summaryKR, "평일")
    }

    func testSummaryKR_WeeklySpecificDays() {
        let rule = RecurrenceRule.weekly(weekdays: [.monday, .friday])
        XCTAssertEqual(rule.summaryKR, "매주 월,금")
    }

    func testSummaryKR_Monthly() {
        let rule = RecurrenceRule.monthly()
        XCTAssertEqual(rule.summaryKR, "매월")
    }

    func testSummaryKR_WithTime() {
        let rule = RecurrenceRule.daily(timeOfDay: TimeOfDay(hour: 9, minute: 0))
        XCTAssertEqual(rule.summaryKR, "매일 오전 9:00")
    }

    func testSummaryEN_Daily() {
        let rule = RecurrenceRule.daily()
        XCTAssertEqual(rule.summaryEN, "Daily")
    }

    func testSummaryEN_Weekdays() {
        let rule = RecurrenceRule.weekdays()
        XCTAssertEqual(rule.summaryEN, "Weekdays")
    }

    // MARK: - Next Occurrence Calculation

    func testNextOccurrence_Daily() {
        // Given: 매일 반복 규칙
        let rule = RecurrenceRule.daily()
        let baseDate = createDate(2026, 2, 1)

        // When: 다음 occurrence 계산
        let next = rule.nextOccurrence(after: baseDate)

        // Then: 1일 후
        XCTAssertNotNil(next)
        let expected = createDate(2026, 2, 2)
        XCTAssertEqual(dateOnly(next!), dateOnly(expected))
    }

    func testNextOccurrence_DailyWithInterval() {
        // Given: 격일 반복 규칙
        let rule = RecurrenceRule.daily(interval: 2)
        let baseDate = createDate(2026, 2, 1)

        // When: 다음 occurrence 계산
        let next = rule.nextOccurrence(after: baseDate)

        // Then: 2일 후
        XCTAssertNotNil(next)
        let expected = createDate(2026, 2, 3)
        XCTAssertEqual(dateOnly(next!), dateOnly(expected))
    }

    func testNextOccurrence_DailyWithTimeOfDay() {
        // Given: 매일 오전 9시 반복
        let rule = RecurrenceRule.daily(timeOfDay: TimeOfDay(hour: 9, minute: 0))
        let baseDate = createDate(2026, 2, 1)

        // When: 다음 occurrence 계산
        let next = rule.nextOccurrence(after: baseDate)

        // Then: 다음 날 오전 9시
        XCTAssertNotNil(next)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: next!), 9)
        XCTAssertEqual(calendar.component(.minute, from: next!), 0)
    }

    func testNextOccurrence_Weekly_NextDayInSameWeek() {
        // Given: 월/수/금 반복, 현재 월요일
        let rule = RecurrenceRule.weekly(weekdays: [.monday, .wednesday, .friday])
        let monday = createDateWithWeekday(2026, 2, 2) // 2026-02-02는 월요일

        // When: 다음 occurrence 계산
        let next = rule.nextOccurrence(after: monday)

        // Then: 수요일 (같은 주)
        XCTAssertNotNil(next)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.weekday, from: next!), Weekday.wednesday.calendarWeekday)
    }

    func testNextOccurrence_Weekly_NextWeek() {
        // Given: 월요일만 반복, 현재 월요일
        let rule = RecurrenceRule.weekly(weekdays: [.monday])
        let monday = createDateWithWeekday(2026, 2, 2) // 2026-02-02는 월요일

        // When: 다음 occurrence 계산
        let next = rule.nextOccurrence(after: monday)

        // Then: 다음 주 월요일
        XCTAssertNotNil(next)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.weekday, from: next!), Weekday.monday.calendarWeekday)

        // 7일 차이
        let days = calendar.dateComponents([.day], from: monday, to: next!).day!
        XCTAssertEqual(days, 7)
    }

    func testNextOccurrence_Monthly() {
        // Given: 매월 반복
        let rule = RecurrenceRule.monthly()
        let baseDate = createDate(2026, 2, 15)

        // When: 다음 occurrence 계산
        let next = rule.nextOccurrence(after: baseDate)

        // Then: 1개월 후
        XCTAssertNotNil(next)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.month, from: next!), 3)
        XCTAssertEqual(calendar.component(.day, from: next!), 15)
    }

    func testNextOccurrence_MonthlyWithInterval() {
        // Given: 격월 반복
        let rule = RecurrenceRule.monthly(interval: 2)
        let baseDate = createDate(2026, 1, 15)

        // When: 다음 occurrence 계산
        let next = rule.nextOccurrence(after: baseDate)

        // Then: 2개월 후
        XCTAssertNotNil(next)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.month, from: next!), 3)
    }

    // MARK: - Test Helpers

    private func createDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components)!
    }

    private func createDateWithWeekday(_ year: Int, _ month: Int, _ day: Int) -> Date {
        createDate(year, month, day)
    }

    private func dateOnly(_ date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: date)
    }

    // MARK: - Codable

    func testCodable_RoundTrip() throws {
        let rule = RecurrenceRule.weekly(
            weekdays: [.monday, .wednesday, .friday],
            interval: 2,
            timeOfDay: TimeOfDay(hour: 10, minute: 30)
        )

        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(RecurrenceRule.self, from: data)

        XCTAssertEqual(decoded.kind, rule.kind)
        XCTAssertEqual(decoded.interval, rule.interval)
        XCTAssertEqual(decoded.weekdays, rule.weekdays)
        XCTAssertEqual(decoded.timeOfDay, rule.timeOfDay)
    }

    func testCodable_AllKinds() throws {
        let rules: [RecurrenceRule] = [
            .daily(),
            .weekly(weekdays: [.monday]),
            .monthly()
        ]

        for rule in rules {
            let data = try JSONEncoder().encode(rule)
            let decoded = try JSONDecoder().decode(RecurrenceRule.self, from: data)
            XCTAssertEqual(decoded.kind, rule.kind)
        }
    }
}
