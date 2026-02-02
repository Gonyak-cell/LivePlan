import XCTest
@testable import AppCore

/// DateTokenParser 테스트
/// - product-decisions.md 5: 날짜/시간 토큰 파싱
/// - testing.md B4/B5: 타임존 안전성
final class DateTokenParserTests: XCTestCase {

    private var sut: DateTokenParser!
    private var referenceDate: Date!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        // 고정된 참조 날짜: 2026-02-02 월요일 10:00
        let components = DateComponents(year: 2026, month: 2, day: 2, hour: 10, minute: 0)
        referenceDate = calendar.date(from: components)!
        sut = DateTokenParser(referenceDate: referenceDate)
    }

    override func tearDown() {
        sut = nil
        referenceDate = nil
        calendar = nil
        super.tearDown()
    }

    // MARK: - Relative Date

    func testParse_Today_Korean() {
        let result = sut.parse("오늘 할 일")

        XCTAssertNotNil(result.date)
        XCTAssertEqual(
            calendar.startOfDay(for: result.date!),
            calendar.startOfDay(for: referenceDate)
        )
        XCTAssertEqual(result.remainingText.trimmingCharacters(in: .whitespaces), "할 일")
    }

    func testParse_Today_English() {
        let result = sut.parse("today meeting")

        XCTAssertNotNil(result.date)
        XCTAssertEqual(
            calendar.startOfDay(for: result.date!),
            calendar.startOfDay(for: referenceDate)
        )
    }

    func testParse_Tomorrow_Korean() {
        let result = sut.parse("내일 회의")

        XCTAssertNotNil(result.date)
        let expectedDate = calendar.date(byAdding: .day, value: 1, to: referenceDate)!
        XCTAssertEqual(
            calendar.startOfDay(for: result.date!),
            calendar.startOfDay(for: expectedDate)
        )
    }

    func testParse_Tomorrow_English() {
        let result = sut.parse("tomorrow meeting")

        XCTAssertNotNil(result.date)
        let expectedDate = calendar.date(byAdding: .day, value: 1, to: referenceDate)!
        XCTAssertEqual(
            calendar.startOfDay(for: result.date!),
            calendar.startOfDay(for: expectedDate)
        )
    }

    func testParse_DayAfterTomorrow() {
        let result = sut.parse("모레 약속")

        XCTAssertNotNil(result.date)
        let expectedDate = calendar.date(byAdding: .day, value: 2, to: referenceDate)!
        XCTAssertEqual(
            calendar.startOfDay(for: result.date!),
            calendar.startOfDay(for: expectedDate)
        )
    }

    // MARK: - Weekday

    func testParse_Weekday_Friday_Korean() {
        let result = sut.parse("금요일 회의")

        XCTAssertNotNil(result.date)
        let weekday = calendar.component(.weekday, from: result.date!)
        XCTAssertEqual(weekday, 6) // 금요일
    }

    func testParse_Weekday_Friday_Short() {
        let result = sut.parse("금 회의")

        XCTAssertNotNil(result.date)
        let weekday = calendar.component(.weekday, from: result.date!)
        XCTAssertEqual(weekday, 6)
    }

    func testParse_Weekday_Monday_NextWeek() {
        // 2026-02-02는 월요일, 다음 월요일은 +7일
        let result = sut.parse("월요일 회의")

        XCTAssertNotNil(result.date)
        let weekday = calendar.component(.weekday, from: result.date!)
        XCTAssertEqual(weekday, 2) // 월요일

        // 다음 주인지 확인
        let daysDiff = calendar.dateComponents([.day], from: referenceDate, to: result.date!).day!
        XCTAssertEqual(daysDiff, 7)
    }

    func testParse_Weekday_Wednesday_ThisWeek() {
        // 2026-02-02는 월요일, 수요일은 +2일
        let result = sut.parse("수요일 회의")

        XCTAssertNotNil(result.date)
        let weekday = calendar.component(.weekday, from: result.date!)
        XCTAssertEqual(weekday, 4) // 수요일

        let daysDiff = calendar.dateComponents([.day], from: referenceDate, to: result.date!).day!
        XCTAssertEqual(daysDiff, 2)
    }

    func testParse_Weekday_English() {
        let result = sut.parse("friday meeting")

        XCTAssertNotNil(result.date)
        let weekday = calendar.component(.weekday, from: result.date!)
        XCTAssertEqual(weekday, 6)
    }

    func testParse_Weekday_EnglishShort() {
        let result = sut.parse("fri meeting")

        XCTAssertNotNil(result.date)
        let weekday = calendar.component(.weekday, from: result.date!)
        XCTAssertEqual(weekday, 6)
    }

    // MARK: - Date Format

    func testParse_DateFormat_MMDD() {
        let result = sut.parse("2/14 발렌타인")

        XCTAssertNotNil(result.date)
        let components = calendar.dateComponents([.month, .day], from: result.date!)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 14)
    }

    func testParse_DateFormat_SingleDigit() {
        let result = sut.parse("3/5 회의")

        XCTAssertNotNil(result.date)
        let components = calendar.dateComponents([.month, .day], from: result.date!)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 5)
    }

    // MARK: - Time Parsing

    func testParse_Time_KoreanPM() {
        let result = sut.parse("오후 3시 회의")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 15)
        XCTAssertEqual(result.time?.minute, 0)
    }

    func testParse_Time_KoreanAM() {
        let result = sut.parse("오전 10시 회의")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 10)
        XCTAssertEqual(result.time?.minute, 0)
    }

    func testParse_Time_KoreanWithMinute() {
        let result = sut.parse("오후 2시 30분 회의")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 14)
        XCTAssertEqual(result.time?.minute, 30)
    }

    func testParse_Time_KoreanMidnight() {
        let result = sut.parse("오전 12시 회의")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 0)
    }

    func testParse_Time_KoreanNoon() {
        let result = sut.parse("오후 12시 회의")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 12)
    }

    func testParse_Time_AmPm() {
        let result = sut.parse("3pm meeting")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 15)
    }

    func testParse_Time_AmPmWithMinute() {
        let result = sut.parse("3:30pm meeting")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 15)
        XCTAssertEqual(result.time?.minute, 30)
    }

    func testParse_Time_AM() {
        let result = sut.parse("10am meeting")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 10)
    }

    func testParse_Time_Military() {
        let result = sut.parse("15:30 회의")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 15)
        XCTAssertEqual(result.time?.minute, 30)
    }

    func testParse_Time_Military_SingleDigitHour() {
        let result = sut.parse("9:00 회의")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 9)
        XCTAssertEqual(result.time?.minute, 0)
    }

    func testParse_Time_SimpleKorean() {
        let result = sut.parse("3시 회의")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 3)
    }

    func testParse_Time_SimpleKoreanWithMinute() {
        let result = sut.parse("15시 30분 회의")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 15)
        XCTAssertEqual(result.time?.minute, 30)
    }

    // MARK: - Combined Date and Time

    func testParse_Combined_DateAndTime() {
        let result = sut.parse("내일 오후 3시 회의")

        XCTAssertNotNil(result.date)
        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 15)
    }

    func testParse_Combined_WeekdayAndTime() {
        let result = sut.parse("금요일 10am 미팅")

        XCTAssertNotNil(result.date)
        let weekday = calendar.component(.weekday, from: result.date!)
        XCTAssertEqual(weekday, 6)

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 10)
    }

    // MARK: - No Match

    func testParse_NoDate_ReturnsNil() {
        let result = sut.parse("그냥 할 일")

        XCTAssertNil(result.date)
        XCTAssertNil(result.time)
        XCTAssertEqual(result.remainingText, "그냥 할 일")
    }

    // MARK: - Remaining Text

    func testParse_RemainingText_PreservesOtherTokens() {
        let result = sut.parse("내일 p1 #work 회의")

        XCTAssertNotNil(result.date)
        XCTAssertTrue(result.remainingText.contains("p1"))
        XCTAssertTrue(result.remainingText.contains("#work"))
        XCTAssertTrue(result.remainingText.contains("회의"))
    }
}
