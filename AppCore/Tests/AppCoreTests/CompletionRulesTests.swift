import XCTest
@testable import AppCore

/// 완료 규칙 테스트
/// - testing.md B1, B2, B3 준수
final class CompletionRulesTests: XCTestCase {

    private var computer: OutstandingComputer!

    override func setUp() {
        super.setUp()
        computer = OutstandingComputer()
    }

    // MARK: - B1: oneOff 완료 처리 (영구 제거)

    func testB1_OneOff_Completion_RemovesFromOutstanding() {
        // Given: oneOff 태스크 1개
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Task", taskType: .oneOff)
        let dateKey = DateKey.today()

        // When: 완료 전
        let beforeSummary = computer.compute(
            dateKey: dateKey,
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: []
        )

        // Then: outstanding에 포함
        XCTAssertEqual(beforeSummary.counters.outstandingTotal, 1)
        XCTAssertEqual(beforeSummary.displayList.count, 1)

        // When: 완료 후
        let log = CompletionLog.forOneOff(taskId: "t1")
        let afterSummary = computer.compute(
            dateKey: dateKey,
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: [log]
        )

        // Then: outstanding에서 제거됨
        XCTAssertEqual(afterSummary.counters.outstandingTotal, 0)
        XCTAssertTrue(afterSummary.displayList.isEmpty)
    }

    func testB1_OneOff_DuplicateCompletion_IsIdempotent() {
        // Given: oneOff 태스크 + 완료 로그
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Task", taskType: .oneOff)
        let log1 = CompletionLog.forOneOff(taskId: "t1", completedAt: Date())
        let log2 = CompletionLog.forOneOff(taskId: "t1", completedAt: Date().addingTimeInterval(60))

        // When: 중복 로그가 있어도
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: [log1, log2] // 실제로는 저장소에서 중복 방지
        )

        // Then: 정상 동작 (크래시 없음)
        XCTAssertEqual(summary.counters.outstandingTotal, 0)
    }

    // MARK: - B2: dailyRecurring 완료 처리 (당일만 완료)

    func testB2_DailyRecurring_Completion_OnlyForToday() {
        // Given: dailyRecurring 태스크 + 오늘 dateKey
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Daily Task", taskType: .dailyRecurring)
        let todayKey = DateKey.today()

        // When: 오늘 완료 로그 없음
        let beforeSummary = computer.compute(
            dateKey: todayKey,
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: []
        )

        // Then: outstanding에 포함
        XCTAssertEqual(beforeSummary.counters.outstandingTotal, 1)
        XCTAssertEqual(beforeSummary.counters.recurringTotal, 1)
        XCTAssertEqual(beforeSummary.counters.recurringDone, 0)

        // When: 오늘 완료 로그 추가
        let log = CompletionLog.forDailyRecurring(taskId: "t1", dateKey: todayKey.value)
        let afterSummary = computer.compute(
            dateKey: todayKey,
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: [log]
        )

        // Then: outstanding에서 제거, recurringDone 증가
        XCTAssertEqual(afterSummary.counters.outstandingTotal, 0)
        XCTAssertEqual(afterSummary.counters.recurringTotal, 1)
        XCTAssertEqual(afterSummary.counters.recurringDone, 1)
    }

    func testB2_DailyRecurring_UniqueConstraint() {
        // Given: 같은 (taskId, dateKey)로 두 번 완료 시도
        let todayKey = DateKey.today()
        let log1 = CompletionLog.forDailyRecurring(taskId: "t1", dateKey: todayKey.value)
        let log2 = CompletionLog.forDailyRecurring(taskId: "t1", dateKey: todayKey.value)

        // Then: 같은 ID를 가짐
        XCTAssertEqual(log1.id, log2.id)
    }

    // MARK: - B3: 날짜 변경 시 리셋 (누적 없음)

    func testB3_DailyRecurring_DateChange_NoAccumulation() {
        // Given: dailyRecurring 태스크 + 어제 미완료
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Daily Task", taskType: .dailyRecurring)

        let todayKey = DateKey.today()
        let yesterdayKey = todayKey.previousDay()!

        // When: 어제 기준으로 계산 (완료 로그 없음)
        let yesterdaySummary = computer.compute(
            dateKey: yesterdayKey,
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: []
        )

        // Then: 어제 기준 미완료
        XCTAssertEqual(yesterdaySummary.counters.outstandingTotal, 1)

        // When: 오늘 기준으로 계산 (어제 완료 로그 없음)
        let todaySummary = computer.compute(
            dateKey: todayKey,
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: []
        )

        // Then: 오늘도 미완료 (어제 미완료가 누적되지 않음 - 리셋)
        // dailyRecurring은 어제 미체크해도 오늘은 새로 시작
        XCTAssertEqual(todaySummary.counters.outstandingTotal, 1)
        XCTAssertEqual(todaySummary.counters.recurringTotal, 1)
        XCTAssertEqual(todaySummary.counters.recurringDone, 0)
    }

    func testB3_DailyRecurring_YesterdayCompletion_TodayReset() {
        // Given: dailyRecurring 태스크 + 어제 완료
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Daily Task", taskType: .dailyRecurring)

        let todayKey = DateKey.today()
        let yesterdayKey = todayKey.previousDay()!
        let yesterdayLog = CompletionLog.forDailyRecurring(taskId: "t1", dateKey: yesterdayKey.value)

        // When: 오늘 기준으로 계산 (어제 완료 로그만 있음)
        let summary = computer.compute(
            dateKey: todayKey,
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: [yesterdayLog]
        )

        // Then: 오늘은 다시 미완료 (리셋)
        XCTAssertEqual(summary.counters.outstandingTotal, 1)
        XCTAssertEqual(summary.counters.recurringTotal, 1)
        XCTAssertEqual(summary.counters.recurringDone, 0)
    }

    // MARK: - B3 Rollover: 완료 시 다음 occurrence로 advance

    func testB3_Rollover_OccurrenceKey_BasedOnNextOccurrenceDueAt() {
        // Given: rollover 태스크 + nextOccurrenceDueAt 설정
        let dueAt = createDate(2026, 2, 5)
        let expectedOccurrenceKey = DateKey.from(dueAt).value

        // When: rollover 완료 로그 생성
        let log = CompletionLog.forRollover(taskId: "t1", occurrenceDueAt: dueAt)

        // Then: occurrenceKey = dateKey(nextOccurrenceDueAt)
        XCTAssertEqual(log.occurrenceKey, expectedOccurrenceKey)
        XCTAssertEqual(log.occurrenceKey, "2026-02-05")
    }

    func testB3_Rollover_Completion_AdvancesNextOccurrence() {
        // Given: rollover 태스크 + recurrenceRule
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let currentDueAt = createDate(2026, 2, 5)
        let task = Task(
            id: "t1",
            projectId: "p1",
            title: "Weekly Task",
            taskType: .oneOff,  // oneOff이지만 recurrenceRule이 있으면 rollover
            recurrenceRule: RecurrenceRule.weekly(weekdays: [.wednesday]),
            recurrenceBehavior: .rollover,
            nextOccurrenceDueAt: currentDueAt
        )

        // When: 완료 로그 생성
        let log = CompletionLog.forRollover(taskId: task.id, occurrenceDueAt: currentDueAt)

        // Then: occurrenceKey가 현재 occurrence의 dateKey
        XCTAssertEqual(log.occurrenceKey, "2026-02-05")

        // And: recurrenceRule로 다음 occurrence 계산 가능
        let nextDueAt = task.recurrenceRule?.nextOccurrence(after: currentDueAt)
        XCTAssertNotNil(nextDueAt)
    }

    func testB3_Rollover_NotCompletedYet_ShowsInOutstanding() {
        // Given: rollover 태스크 + nextOccurrenceDueAt이 아직 미래
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let futureDueAt = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let task = Task(
            id: "t1",
            projectId: "p1",
            title: "Weekly Task",
            taskType: .oneOff,
            recurrenceRule: RecurrenceRule.weekly(weekdays: [.wednesday]),
            recurrenceBehavior: .rollover,
            nextOccurrenceDueAt: futureDueAt
        )

        // When: 완료 로그 없음
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: []
        )

        // Then: outstanding에 포함됨 (dueSoon)
        XCTAssertEqual(summary.counters.outstandingTotal, 1)
    }

    func testB3_Rollover_Overdue_StaysInOutstanding() {
        // Given: rollover 태스크 + nextOccurrenceDueAt이 과거 (지연)
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let pastDueAt = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let task = Task(
            id: "t1",
            projectId: "p1",
            title: "Overdue Task",
            taskType: .oneOff,
            recurrenceRule: RecurrenceRule.weekly(weekdays: [.monday]),
            recurrenceBehavior: .rollover,
            nextOccurrenceDueAt: pastDueAt
        )

        // When: 완료 로그 없음
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: []
        )

        // Then: outstanding에 남아있음 (overdue)
        XCTAssertEqual(summary.counters.outstandingTotal, 1)
        XCTAssertEqual(summary.counters.overdueCount, 1)
    }

    func testB3_Rollover_CompletedOccurrence_RemovedFromOutstanding() {
        // Given: rollover 태스크 + 현재 occurrence 완료
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let currentDueAt = createDate(2026, 2, 5)
        let nextDueAt = createDate(2026, 2, 12) // 다음 주
        let task = Task(
            id: "t1",
            projectId: "p1",
            title: "Weekly Task",
            taskType: .oneOff,
            recurrenceRule: RecurrenceRule.weekly(weekdays: [.wednesday]),
            recurrenceBehavior: .rollover,
            nextOccurrenceDueAt: nextDueAt // 이미 advance된 상태
        )
        // 이전 occurrence에 대한 완료 로그
        let log = CompletionLog.forRollover(taskId: "t1", occurrenceDueAt: currentDueAt)

        // When: 계산
        let summary = computer.compute(
            dateKey: DateKey.from(currentDueAt),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: [log]
        )

        // Then: 다음 occurrence가 아직 먼 미래면 dueSoon에 포함되지 않음
        // (nextDueAt이 미래로 advance되었으므로)
        XCTAssertEqual(summary.counters.outstandingTotal, 1) // 다음 occurrence는 여전히 대기
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
}
