import XCTest
@testable import AppCore

/// QuickAddParser 테스트
/// - product-decisions.md 5 준수: 제한된 자연어/토큰 파싱
/// - testing.md: 파싱 성공/실패 케이스
final class QuickAddParserTests: XCTestCase {

    private var sut: QuickAddParser!
    private var referenceDate: Date!

    override func setUp() {
        super.setUp()
        // 고정된 참조 날짜: 2026-02-02 월요일 10:00
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let components = DateComponents(year: 2026, month: 2, day: 2, hour: 10, minute: 0)
        referenceDate = calendar.date(from: components)!
        sut = QuickAddParser(referenceDate: referenceDate)
    }

    override func tearDown() {
        sut = nil
        referenceDate = nil
        super.tearDown()
    }

    // MARK: - Basic Parsing

    func testParse_PlainText_ReturnsTitle() {
        let result = sut.parse("그냥 할 일")

        XCTAssertEqual(result.title, "그냥 할 일")
        XCTAssertFalse(result.hasAnyParsedTokens)
    }

    func testParse_EmptyString_ReturnsEmptyTitle() {
        let result = sut.parse("")

        XCTAssertEqual(result.title, "")
    }

    func testParse_WhitespaceOnly_ReturnsEmptyTitle() {
        let result = sut.parse("   ")

        XCTAssertEqual(result.title, "")
    }

    // MARK: - Priority Parsing (P2-M5-03)

    func testParse_PriorityP1Lowercase() {
        let result = sut.parse("할 일 p1")

        XCTAssertEqual(result.priority, .p1)
        XCTAssertEqual(result.title, "할 일")
    }

    func testParse_PriorityP2Uppercase() {
        let result = sut.parse("P2 할 일")

        XCTAssertEqual(result.priority, .p2)
        XCTAssertEqual(result.title, "할 일")
    }

    func testParse_PriorityP3InMiddle() {
        let result = sut.parse("중요한 p3 회의")

        XCTAssertEqual(result.priority, .p3)
        XCTAssertEqual(result.title, "중요한 회의")
    }

    func testParse_PriorityP4() {
        let result = sut.parse("할 일 p4")

        XCTAssertEqual(result.priority, .p4)
    }

    func testParse_NoPriority_ReturnsNil() {
        let result = sut.parse("할 일")

        XCTAssertNil(result.priority)
    }

    func testParse_InvalidPriority_Ignored() {
        let result = sut.parse("p5 할 일")

        XCTAssertNil(result.priority)
        XCTAssertEqual(result.title, "p5 할 일")
    }

    // MARK: - Tag Parsing (P2-M5-04)

    func testParse_SingleTag() {
        let result = sut.parse("회의 #work")

        XCTAssertEqual(result.tagNames, ["work"])
        XCTAssertEqual(result.title, "회의")
    }

    func testParse_MultipleTags() {
        let result = sut.parse("#urgent #work 회의")

        XCTAssertEqual(result.tagNames, ["urgent", "work"])
        XCTAssertEqual(result.title, "회의")
    }

    func testParse_TagWithKorean() {
        let result = sut.parse("회의 #업무")

        XCTAssertEqual(result.tagNames, ["업무"])
    }

    func testParse_TagInMiddle() {
        let result = sut.parse("중요한 #work 회의")

        XCTAssertEqual(result.tagNames, ["work"])
        XCTAssertEqual(result.title, "중요한 회의")
    }

    func testParse_NoTags_ReturnsEmpty() {
        let result = sut.parse("할 일")

        XCTAssertTrue(result.tagNames.isEmpty)
    }

    // MARK: - Project Parsing (P2-M5-05)

    func testParse_Project() {
        let result = sut.parse("회의 @프로젝트명")

        XCTAssertEqual(result.projectName, "프로젝트명")
        XCTAssertEqual(result.title, "회의")
    }

    func testParse_ProjectEnglish() {
        let result = sut.parse("@work 회의")

        XCTAssertEqual(result.projectName, "work")
    }

    func testParse_NoProject_ReturnsNil() {
        let result = sut.parse("할 일")

        XCTAssertNil(result.projectName)
    }

    // MARK: - Section Parsing (P2-M5-05)

    func testParse_SectionWithSlash() {
        let result = sut.parse("회의 /섹션명")

        XCTAssertEqual(result.sectionName, "섹션명")
        XCTAssertEqual(result.title, "회의")
    }

    func testParse_SectionWithDoubleColon() {
        let result = sut.parse("회의 ::섹션명")

        XCTAssertEqual(result.sectionName, "섹션명")
    }

    func testParse_NoSection_ReturnsNil() {
        let result = sut.parse("할 일")

        XCTAssertNil(result.sectionName)
    }

    // MARK: - Date Parsing (P2-M5-02)

    func testParse_Tomorrow() {
        let result = sut.parse("내일 회의")

        XCTAssertNotNil(result.dueDate)
        // 2026-02-02 + 1일 = 2026-02-03
        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .day, value: 1, to: referenceDate)!
        XCTAssertEqual(
            calendar.startOfDay(for: result.dueDate!),
            calendar.startOfDay(for: expectedDate)
        )
        XCTAssertEqual(result.title, "회의")
    }

    func testParse_Today() {
        let result = sut.parse("오늘 할 일")

        XCTAssertNotNil(result.dueDate)
        let calendar = Calendar.current
        XCTAssertEqual(
            calendar.startOfDay(for: result.dueDate!),
            calendar.startOfDay(for: referenceDate)
        )
    }

    func testParse_DayAfterTomorrow() {
        let result = sut.parse("모레 회의")

        XCTAssertNotNil(result.dueDate)
        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .day, value: 2, to: referenceDate)!
        XCTAssertEqual(
            calendar.startOfDay(for: result.dueDate!),
            calendar.startOfDay(for: expectedDate)
        )
    }

    func testParse_Weekday_Friday() {
        let result = sut.parse("금요일 회의")

        XCTAssertNotNil(result.dueDate)
        // 2026-02-02는 월요일, 금요일은 +4일 = 2026-02-06
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: result.dueDate!)
        XCTAssertEqual(weekday, 6) // 금요일
    }

    func testParse_Weekday_Monday() {
        let result = sut.parse("월요일 회의")

        XCTAssertNotNil(result.dueDate)
        // 다음 주 월요일 = +7일
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: result.dueDate!)
        XCTAssertEqual(weekday, 2) // 월요일
    }

    func testParse_DateFormat() {
        let result = sut.parse("2/14 회의")

        XCTAssertNotNil(result.dueDate)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: result.dueDate!)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 14)
    }

    // MARK: - Time Parsing (P2-M5-02)

    func testParse_KoreanTimePM() {
        let result = sut.parse("오후 3시 회의")

        XCTAssertNotNil(result.timeOfDay)
        XCTAssertEqual(result.timeOfDay?.hour, 15)
        XCTAssertEqual(result.timeOfDay?.minute, 0)
    }

    func testParse_KoreanTimeAM() {
        let result = sut.parse("오전 10시 30분 회의")

        XCTAssertNotNil(result.timeOfDay)
        XCTAssertEqual(result.timeOfDay?.hour, 10)
        XCTAssertEqual(result.timeOfDay?.minute, 30)
    }

    func testParse_AmPmTime() {
        let result = sut.parse("3pm 회의")

        XCTAssertNotNil(result.timeOfDay)
        XCTAssertEqual(result.timeOfDay?.hour, 15)
    }

    func testParse_MilitaryTime() {
        let result = sut.parse("15:30 회의")

        XCTAssertNotNil(result.timeOfDay)
        XCTAssertEqual(result.timeOfDay?.hour, 15)
        XCTAssertEqual(result.timeOfDay?.minute, 30)
    }

    func testParse_SimpleKoreanTime() {
        let result = sut.parse("3시 회의")

        XCTAssertNotNil(result.timeOfDay)
        XCTAssertEqual(result.timeOfDay?.hour, 3)
        XCTAssertEqual(result.timeOfDay?.minute, 0)
    }

    // MARK: - Combined Parsing

    func testParse_Combined_Full() {
        let result = sut.parse("내일 오후 3시 p1 #work @프로젝트 회의")

        XCTAssertNotNil(result.dueDate)
        XCTAssertEqual(result.timeOfDay?.hour, 15)
        XCTAssertEqual(result.priority, .p1)
        XCTAssertEqual(result.tagNames, ["work"])
        XCTAssertEqual(result.projectName, "프로젝트")
        XCTAssertEqual(result.title, "회의")
        XCTAssertTrue(result.hasAnyParsedTokens)
    }

    func testParse_Combined_PriorityAndTags() {
        let result = sut.parse("p2 #urgent #work 리뷰")

        XCTAssertEqual(result.priority, .p2)
        XCTAssertEqual(result.tagNames, ["urgent", "work"])
        XCTAssertEqual(result.title, "리뷰")
    }

    func testParse_Combined_DateAndTime() {
        let result = sut.parse("내일 오후 2시 미팅")

        XCTAssertNotNil(result.dueDate)
        XCTAssertEqual(result.timeOfDay?.hour, 14)
        XCTAssertEqual(result.title, "미팅")
    }

    func testParse_Combined_ProjectAndSection() {
        let result = sut.parse("@work /todo 태스크")

        XCTAssertEqual(result.projectName, "work")
        XCTAssertEqual(result.sectionName, "todo")
        XCTAssertEqual(result.title, "태스크")
    }

    // MARK: - Fail-Safe (파싱 실패 시 제목만)

    func testParse_TitlePreserved_WhenAllTokensRemoved() {
        let result = sut.parse("p1 #work @project")

        // 제목이 완전히 비면 원문 사용
        XCTAssertFalse(result.title.isEmpty)
    }

    func testParse_InvalidTokens_IgnoredAndPreserved() {
        let result = sut.parse("p5 회의") // p5는 유효하지 않음

        XCTAssertNil(result.priority)
        XCTAssertEqual(result.title, "p5 회의")
    }

    // MARK: - TimeOfDayValue

    func testTimeOfDayValue_Formatted() {
        let time = TimeOfDayValue(hour: 15, minute: 30)

        XCTAssertEqual(time.formatted, "15:30")
    }

    func testTimeOfDayValue_FormattedKR() {
        let time = TimeOfDayValue(hour: 15, minute: 30)

        XCTAssertEqual(time.formattedKR, "오후 3시 30분")
    }

    func testTimeOfDayValue_FormattedKR_NoMinute() {
        let time = TimeOfDayValue(hour: 15, minute: 0)

        XCTAssertEqual(time.formattedKR, "오후 3시")
    }

    func testTimeOfDayValue_BoundsCheck() {
        let time = TimeOfDayValue(hour: 25, minute: 70)

        XCTAssertEqual(time.hour, 23) // 최대값으로 제한
        XCTAssertEqual(time.minute, 59) // 최대값으로 제한
    }

    // MARK: - ParsedTask.combinedDueDate

    func testParsedTask_CombinedDueDate_WithTime() {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: referenceDate)
        let time = TimeOfDayValue(hour: 14, minute: 30)

        let parsed = ParsedTask(
            title: "테스트",
            dueDate: date,
            timeOfDay: time
        )

        let combined = parsed.combinedDueDate()
        XCTAssertNotNil(combined)

        let components = calendar.dateComponents([.hour, .minute], from: combined!)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 30)
    }

    func testParsedTask_CombinedDueDate_WithoutTime() {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: referenceDate)

        let parsed = ParsedTask(
            title: "테스트",
            dueDate: date,
            timeOfDay: nil
        )

        let combined = parsed.combinedDueDate()
        XCTAssertEqual(combined, date)
    }

    func testParsedTask_CombinedDueDate_WithoutDate() {
        let parsed = ParsedTask(
            title: "테스트",
            dueDate: nil,
            timeOfDay: TimeOfDayValue(hour: 14, minute: 30)
        )

        XCTAssertNil(parsed.combinedDueDate())
    }
}
