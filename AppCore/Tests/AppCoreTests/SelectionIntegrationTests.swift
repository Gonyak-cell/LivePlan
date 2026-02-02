import XCTest
@testable import AppCore

/// M6-7: 전체 선정 알고리즘 통합 회귀 테스트
/// - lockscreen.md B: 전체 우선순위 그룹(G1-G6) 및 tie-breaker 검증
/// - testing.md: 결정론(determinism) 보장 및 회귀 방지
final class SelectionIntegrationTests: XCTestCase {

    private var computer: OutstandingComputer!

    override func setUp() {
        super.setUp()
        computer = OutstandingComputer()
    }

    // MARK: - Helper Functions

    private func createDate(
        year: Int = 2026,
        month: Int = 2,
        day: Int = 2,
        hour: Int = 12,
        minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    // MARK: - A. 전체 우선순위 그룹 통합 테스트

    /// M6-7-A1: 모든 6개 우선순위 그룹이 올바른 순서로 정렬되는지 검증
    /// G1(doing) > G2(overdue) > G3(dueSoon) > G4(P1) > G5(habitReset) > G6(나머지)
    func testIntegration_AllSixPriorityGroups_CorrectOrdering() {
        // Given: 각 그룹에 해당하는 태스크 1개씩 (총 6개)
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()

        // G1: doing 태스크 (작업 중)
        let doingTask = Task(
            id: "t_g1_doing",
            projectId: "p1",
            title: "Doing Task",
            taskType: .oneOff,
            createdAt: now,
            workflowState: .doing
        )

        // G2: overdue 태스크
        let overdueTask = Task(
            id: "t_g2_overdue",
            projectId: "p1",
            title: "Overdue Task",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(-7200), // 2시간 전
            createdAt: now
        )

        // G3: dueSoon 태스크 (24시간 이내)
        let dueSoonTask = Task(
            id: "t_g3_dueSoon",
            projectId: "p1",
            title: "Due Soon Task",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(3600), // 1시간 후
            createdAt: now
        )

        // G4: P1 priority 태스크 (dueDate 없음)
        let p1Task = Task(
            id: "t_g4_p1",
            projectId: "p1",
            title: "P1 Task",
            taskType: .oneOff,
            priority: .p1,
            createdAt: now
        )

        // G5: habitReset recurring 태스크
        let habitResetTask = Task(
            id: "t_g5_habit",
            projectId: "p1",
            title: "Habit Task",
            taskType: .dailyRecurring,
            createdAt: now
        )

        // G6: 일반 oneOff 태스크 (나머지)
        let normalTask = Task(
            id: "t_g6_normal",
            projectId: "p1",
            title: "Normal Task",
            taskType: .oneOff,
            createdAt: now
        )

        // When: 순서를 섞어서 입력
        let tasks = [normalTask, p1Task, dueSoonTask, habitResetTask, overdueTask, doingTask]
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: tasks,
            completionLogs: [],
            topN: 6,
            now: now
        )

        // Then: G1 > G2 > G3 > G4 > G5 > G6 순서
        XCTAssertEqual(summary.displayList.count, 6)
        XCTAssertEqual(summary.displayList[0].id, "t_g1_doing", "G1(doing) 먼저")
        XCTAssertEqual(summary.displayList[1].id, "t_g2_overdue", "G2(overdue) 두 번째")
        XCTAssertEqual(summary.displayList[2].id, "t_g3_dueSoon", "G3(dueSoon) 세 번째")
        XCTAssertEqual(summary.displayList[3].id, "t_g4_p1", "G4(P1) 네 번째")
        XCTAssertEqual(summary.displayList[4].id, "t_g5_habit", "G5(habitReset) 다섯 번째")
        XCTAssertEqual(summary.displayList[5].id, "t_g6_normal", "G6(나머지) 마지막")
    }

    /// M6-7-A2: 동일 그룹 내 여러 태스크가 있을 때 tie-breaker 순서 검증
    func testIntegration_SameGroupMultipleTasks_TiebreakerChain() {
        // Given: G6 그룹에 여러 태스크 (tie-breaker 검증용)
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()

        // dueDate로 tie-break
        let taskDue1 = Task(
            id: "t_due_early",
            projectId: "p1",
            title: "Due Early",
            taskType: .oneOff,
            priority: .p4,
            dueDate: now.addingTimeInterval(86400 * 2), // 2일 후
            createdAt: now
        )
        let taskDue2 = Task(
            id: "t_due_late",
            projectId: "p1",
            title: "Due Late",
            taskType: .oneOff,
            priority: .p4,
            dueDate: now.addingTimeInterval(86400 * 3), // 3일 후
            createdAt: now
        )

        // priority로 tie-break (dueDate 없음)
        let taskP2 = Task(
            id: "t_p2",
            projectId: "p1",
            title: "P2 Task",
            taskType: .oneOff,
            priority: .p2,
            createdAt: now
        )
        let taskP3 = Task(
            id: "t_p3",
            projectId: "p1",
            title: "P3 Task",
            taskType: .oneOff,
            priority: .p3,
            createdAt: now
        )

        // createdAt으로 tie-break (같은 priority)
        let taskEarly = Task(
            id: "t_early",
            projectId: "p1",
            title: "Early Created",
            taskType: .oneOff,
            priority: .p4,
            createdAt: now.addingTimeInterval(-3600)
        )
        let taskLate = Task(
            id: "t_late",
            projectId: "p1",
            title: "Late Created",
            taskType: .oneOff,
            priority: .p4,
            createdAt: now
        )

        // When
        let tasks = [taskLate, taskP3, taskDue2, taskEarly, taskP2, taskDue1]
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: tasks,
            completionLogs: [],
            topN: 10,
            now: now
        )

        // Then: dueDate 있는 것 먼저, 그 다음 priority 순
        XCTAssertEqual(summary.displayList.count, 6)
        XCTAssertEqual(summary.displayList[0].id, "t_due_early")
        XCTAssertEqual(summary.displayList[1].id, "t_due_late")
        XCTAssertEqual(summary.displayList[2].id, "t_p2")
        XCTAssertEqual(summary.displayList[3].id, "t_p3")
        XCTAssertEqual(summary.displayList[4].id, "t_early")
        XCTAssertEqual(summary.displayList[5].id, "t_late")
    }

    /// M6-7-A3: G1(doing) + G2(overdue) 조합에서 doing이 항상 우선
    func testIntegration_DoingOverridesOverdue() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()

        let overdueDoingTask = Task(
            id: "t_overdue_doing",
            projectId: "p1",
            title: "Overdue Doing",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(-7200),
            createdAt: now,
            workflowState: .doing
        )

        let overdueTodoTask = Task(
            id: "t_overdue_todo",
            projectId: "p1",
            title: "Overdue Todo",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(-3600),
            createdAt: now,
            workflowState: .todo
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [overdueTodoTask, overdueDoingTask],
            completionLogs: [],
            now: now
        )

        // Then: doing이 먼저 (G1 > G2)
        XCTAssertEqual(summary.displayList.count, 2)
        XCTAssertEqual(summary.displayList[0].id, "t_overdue_doing")
        XCTAssertEqual(summary.displayList[1].id, "t_overdue_todo")
    }

    // MARK: - B. 복합 시나리오 테스트

    /// M6-7-B1: 다중 프로젝트에서 pinnedFirst 정책 검증
    func testIntegration_MultiProject_PinnedFirst() {
        // Given: 3개 프로젝트 (1개 핀)
        let pinnedProject = Project(id: "pinned", title: "Pinned", startDate: Date())
        let project2 = Project(id: "p2", title: "Project 2", startDate: Date())
        let project3 = Project(id: "p3", title: "Project 3", startDate: Date())
        let now = createDate()

        let pinnedTask1 = Task(id: "pt1", projectId: "pinned", title: "Pinned 1", taskType: .oneOff, createdAt: now)
        let pinnedTask2 = Task(id: "pt2", projectId: "pinned", title: "Pinned 2", taskType: .dailyRecurring, createdAt: now)

        let otherP1Task = Task(
            id: "other_p1",
            projectId: "p2",
            title: "Other P1",
            taskType: .oneOff,
            priority: .p1,
            createdAt: now
        )

        // When: pinnedFirst 정책
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .pinnedFirst(projectId: "pinned"),
            privacyMode: .visible,
            projects: [pinnedProject, project2, project3],
            tasks: [pinnedTask1, pinnedTask2, otherP1Task],
            completionLogs: [],
            now: now
        )

        // Then: 핀 프로젝트 태스크만 포함
        XCTAssertEqual(summary.counters.outstandingTotal, 2)
        XCTAssertEqual(summary.displayList.count, 2)
        XCTAssertTrue(summary.displayList.allSatisfy { $0.id.hasPrefix("pt") })
    }

    /// M6-7-B2: 복잡한 blocking 관계에서 필터링 검증
    func testIntegration_ComplexBlocking() {
        // Given: A blocks B, B blocks C (체인)
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()

        let taskA = Task(id: "a", projectId: "p1", title: "Task A", taskType: .oneOff, createdAt: now)
        let taskB = Task(id: "b", projectId: "p1", title: "Task B", taskType: .oneOff, createdAt: now, blockedByTaskIds: ["a"])
        let taskC = Task(id: "c", projectId: "p1", title: "Task C", taskType: .oneOff, createdAt: now, blockedByTaskIds: ["b"])
        let taskD = Task(id: "d", projectId: "p1", title: "Task D", taskType: .oneOff, createdAt: now.addingTimeInterval(3600))

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [taskA, taskB, taskC, taskD],
            completionLogs: [],
            now: now
        )

        // Then: A, D만 displayList에 포함 (B, C는 blocked)
        XCTAssertEqual(summary.displayList.count, 2)
        XCTAssertEqual(summary.displayList[0].id, "a")
        XCTAssertEqual(summary.displayList[1].id, "d")
        XCTAssertEqual(summary.counters.blockedCount, 2)
    }

    /// M6-7-B3: 완료 처리와 우선순위 그룹 통합
    func testIntegration_CompletionWithPriorityGroups() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()
        let todayKey = DateKey.from(now)

        let doingCompleted = Task(id: "doing_done", projectId: "p1", title: "Doing Done", taskType: .oneOff, createdAt: now, workflowState: .doing)
        let overduePending = Task(id: "overdue_pending", projectId: "p1", title: "Overdue Pending", taskType: .oneOff, dueDate: now.addingTimeInterval(-3600), createdAt: now)
        let habitDone = Task(id: "habit_done", projectId: "p1", title: "Habit Done", taskType: .dailyRecurring, createdAt: now)
        let habitPending = Task(id: "habit_pending", projectId: "p1", title: "Habit Pending", taskType: .dailyRecurring, createdAt: now.addingTimeInterval(3600))

        let completionLogs = [
            CompletionLog.forOneOff(taskId: "doing_done"),
            CompletionLog.forDailyRecurring(taskId: "habit_done", dateKey: todayKey.value)
        ]

        // When
        let summary = computer.compute(
            dateKey: todayKey,
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [doingCompleted, overduePending, habitDone, habitPending],
            completionLogs: completionLogs,
            now: now
        )

        // Then: 완료된 태스크 제외
        XCTAssertEqual(summary.counters.outstandingTotal, 2)
        XCTAssertEqual(summary.displayList[0].id, "overdue_pending")
        XCTAssertEqual(summary.displayList[1].id, "habit_pending")
        XCTAssertEqual(summary.counters.recurringTotal, 2)
        XCTAssertEqual(summary.counters.recurringDone, 1)
    }

    // MARK: - C. Rollover Recurring 통합 테스트

    /// M6-7-C1: Rollover 태스크가 overdue 그룹에 올바르게 분류됨
    func testIntegration_RolloverTask_OverdueClassification() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()

        let rolloverOverdue = Task(
            id: "rollover_overdue",
            projectId: "p1",
            title: "Rollover Overdue",
            taskType: .oneOff,
            createdAt: now,
            nextOccurrenceDueAt: now.addingTimeInterval(-7200),
            recurrenceRule: RecurrenceRule(kind: .daily, interval: 1),
            recurrenceBehavior: .rollover
        )

        let normalTask = Task(id: "normal", projectId: "p1", title: "Normal", taskType: .oneOff, createdAt: now)

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [normalTask, rolloverOverdue],
            completionLogs: [],
            now: now
        )

        // Then: rollover overdue가 먼저 (G2)
        XCTAssertEqual(summary.displayList.count, 2)
        XCTAssertEqual(summary.displayList[0].id, "rollover_overdue")
        XCTAssertTrue(summary.displayList[0].isOverdue)
    }

    /// M6-7-C2: Rollover 완료 처리 검증
    func testIntegration_RolloverTask_Completion() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()
        let occurrenceDueAt = now.addingTimeInterval(-3600)

        let rolloverTask = Task(
            id: "rollover",
            projectId: "p1",
            title: "Rollover",
            taskType: .oneOff,
            createdAt: now,
            nextOccurrenceDueAt: occurrenceDueAt,
            recurrenceRule: RecurrenceRule(kind: .daily, interval: 1),
            recurrenceBehavior: .rollover
        )

        let log = CompletionLog.forRollover(taskId: "rollover", occurrenceDueAt: occurrenceDueAt)

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [rolloverTask],
            completionLogs: [log],
            now: now
        )

        // Then: 완료된 rollover는 제외
        XCTAssertEqual(summary.counters.outstandingTotal, 0)
        XCTAssertTrue(summary.displayList.isEmpty)
    }

    // MARK: - D. 결정론(Determinism) 보장 테스트

    /// M6-7-D1: 동일한 입력은 항상 동일한 출력을 생성
    func testIntegration_Determinism_SameInputSameOutput() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()

        let tasks = (1...10).map { i in
            Task(
                id: "t\(i)",
                projectId: "p1",
                title: "Task \(i)",
                taskType: i % 2 == 0 ? .dailyRecurring : .oneOff,
                priority: Priority(rawValue: (i % 4) + 1) ?? .p4,
                dueDate: i % 3 == 0 ? now.addingTimeInterval(Double(i) * 3600) : nil,
                createdAt: now.addingTimeInterval(Double(i) * -3600)
            )
        }

        // When: 100번 반복 실행
        let results = (1...100).map { _ in
            computer.compute(
                dateKey: DateKey.today(),
                policy: .todayOverview,
                privacyMode: .visible,
                projects: [project],
                tasks: tasks.shuffled(),
                completionLogs: [],
                now: now
            )
        }

        // Then: 모든 결과가 동일
        let firstResult = results[0]
        for (index, result) in results.enumerated() {
            XCTAssertEqual(
                result.displayList.map(\.id),
                firstResult.displayList.map(\.id),
                "결과 \(index)가 첫 번째 결과와 다름"
            )
        }
    }

    /// M6-7-D2: 모든 tie-breaker 조건이 동일할 때 ID로 결정론 보장
    func testIntegration_Determinism_FallbackToId() {
        // Given: 모든 조건 동일 (ID만 다름)
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()

        let tasks = ["zebra", "alpha", "middle", "beta"].map { id in
            Task(id: id, projectId: "p1", title: "Task", taskType: .oneOff, priority: .p4, createdAt: now)
        }

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: tasks,
            completionLogs: [],
            now: now
        )

        // Then: ID 알파벳 순서
        XCTAssertEqual(summary.displayList.map(\.id), ["alpha", "beta", "middle", "zebra"])
    }

    // MARK: - E. 카운터 정확성 통합 테스트

    /// M6-7-E1: 모든 카운터가 복잡한 시나리오에서 정확히 계산됨
    func testIntegration_AllCountersAccuracy() {
        // Given: 복잡한 조합
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()
        let todayKey = DateKey.from(now)

        let overdue1 = Task(id: "overdue1", projectId: "p1", title: "Overdue 1", taskType: .oneOff, dueDate: now.addingTimeInterval(-3600), createdAt: now)
        let overdue2 = Task(id: "overdue2", projectId: "p1", title: "Overdue 2", taskType: .oneOff, dueDate: now.addingTimeInterval(-7200), createdAt: now)
        let dueSoon1 = Task(id: "dueSoon1", projectId: "p1", title: "Due Soon 1", taskType: .oneOff, dueDate: now.addingTimeInterval(3600), createdAt: now)
        let p1_1 = Task(id: "p1_1", projectId: "p1", title: "P1 1", taskType: .oneOff, priority: .p1, createdAt: now)
        let p1_2 = Task(id: "p1_2", projectId: "p1", title: "P1 2", taskType: .oneOff, priority: .p1, createdAt: now)
        let doing1 = Task(id: "doing1", projectId: "p1", title: "Doing 1", taskType: .oneOff, createdAt: now, workflowState: .doing)
        let recurring1 = Task(id: "recurring1", projectId: "p1", title: "Recurring 1", taskType: .dailyRecurring, createdAt: now)
        let recurring2 = Task(id: "recurring2", projectId: "p1", title: "Recurring 2", taskType: .dailyRecurring, createdAt: now)
        let recurring3 = Task(id: "recurring3", projectId: "p1", title: "Recurring 3", taskType: .dailyRecurring, createdAt: now)
        let blocker = Task(id: "blocker", projectId: "p1", title: "Blocker", taskType: .oneOff, createdAt: now)
        let blocked1 = Task(id: "blocked1", projectId: "p1", title: "Blocked 1", taskType: .oneOff, createdAt: now, blockedByTaskIds: ["blocker"])
        let blocked2 = Task(id: "blocked2", projectId: "p1", title: "Blocked 2", taskType: .oneOff, createdAt: now, blockedByTaskIds: ["blocker"])

        let tasks = [overdue1, overdue2, dueSoon1, p1_1, p1_2, doing1, recurring1, recurring2, recurring3, blocker, blocked1, blocked2]
        let logs = [CompletionLog.forDailyRecurring(taskId: "recurring1", dateKey: todayKey.value)]

        // When
        let summary = computer.compute(
            dateKey: todayKey,
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: tasks,
            completionLogs: logs,
            now: now
        )

        // Then: 각 카운터 검증
        XCTAssertEqual(summary.counters.outstandingTotal, 9) // 12 - 2 blocked - 1 recurring done
        XCTAssertEqual(summary.counters.overdueCount, 2)
        XCTAssertEqual(summary.counters.dueSoonCount, 1)
        XCTAssertEqual(summary.counters.p1Count, 2)
        XCTAssertEqual(summary.counters.doingCount, 1)
        XCTAssertEqual(summary.counters.recurringTotal, 3)
        XCTAssertEqual(summary.counters.recurringDone, 1)
        XCTAssertEqual(summary.counters.blockedCount, 2)
    }

    /// M6-7-E2: 빈 상태에서 카운터가 모두 0
    func testIntegration_EmptyStateCounters() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [],
            completionLogs: []
        )

        // Then
        XCTAssertEqual(summary.counters.outstandingTotal, 0)
        XCTAssertEqual(summary.counters.overdueCount, 0)
        XCTAssertEqual(summary.counters.dueSoonCount, 0)
        XCTAssertEqual(summary.counters.p1Count, 0)
        XCTAssertEqual(summary.counters.doingCount, 0)
        XCTAssertEqual(summary.counters.recurringTotal, 0)
        XCTAssertEqual(summary.counters.recurringDone, 0)
        XCTAssertEqual(summary.counters.blockedCount, 0)
    }

    // MARK: - F. 프라이버시 모드 통합 테스트

    /// M6-7-F1: 프라이버시 모드가 모든 우선순위 그룹에 적용됨
    func testIntegration_PrivacyMode_AllGroups() {
        // Given
        let project = Project(id: "p1", title: "Secret Project", startDate: Date())
        let now = createDate()

        let doingTask = Task(id: "doing", projectId: "p1", title: "Secret Doing", taskType: .oneOff, createdAt: now, workflowState: .doing)
        let overdueTask = Task(id: "overdue", projectId: "p1", title: "Secret Overdue", taskType: .oneOff, dueDate: now.addingTimeInterval(-3600), createdAt: now)
        let p1Task = Task(id: "p1", projectId: "p1", title: "Secret P1", taskType: .oneOff, priority: .p1, createdAt: now)

        // When: masked 모드
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .masked,
            projects: [project],
            tasks: [doingTask, overdueTask, p1Task],
            completionLogs: [],
            now: now
        )

        // Then: 제목은 마스킹되지만 다른 속성은 유지
        XCTAssertEqual(summary.displayList.count, 3)
        XCTAssertEqual(summary.displayList[0].displayTitle, "할 일 1")
        XCTAssertEqual(summary.displayList[1].displayTitle, "할 일 2")
        XCTAssertEqual(summary.displayList[2].displayTitle, "할 일 3")
        XCTAssertTrue(summary.displayList[0].isDoing)
        XCTAssertTrue(summary.displayList[1].isOverdue)
        XCTAssertTrue(summary.displayList[2].isP1)
    }

    /// M6-7-F2: hidden 모드에서 제목이 빈 문자열
    func testIntegration_PrivacyMode_Hidden() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Secret Task", taskType: .oneOff)

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .hidden,
            projects: [project],
            tasks: [task],
            completionLogs: []
        )

        // Then
        XCTAssertEqual(summary.displayList.count, 1)
        XCTAssertEqual(summary.displayList[0].displayTitle, "")
    }

    // MARK: - G. 경계 조건 테스트

    /// M6-7-G1: dueSoon 경계 (24시간)
    func testIntegration_DueSoonBoundary() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()

        let exactBoundaryTask = Task(
            id: "exact_boundary",
            projectId: "p1",
            title: "Exact 24h",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(24 * 3600),
            createdAt: now
        )
        let justUnderTask = Task(
            id: "just_under",
            projectId: "p1",
            title: "Just Under 24h",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(24 * 3600 - 60),
            createdAt: now
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [exactBoundaryTask, justUnderTask],
            completionLogs: [],
            now: now
        )

        // Then
        XCTAssertEqual(summary.counters.dueSoonCount, 2)
    }

    /// M6-7-G2: Top N 제한이 우선순위 순서를 유지
    func testIntegration_TopNPreservesPriorityOrder() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()

        let tasks: [Task] = [
            Task(id: "g1_1", projectId: "p1", title: "G1_1", taskType: .oneOff, createdAt: now, workflowState: .doing),
            Task(id: "g1_2", projectId: "p1", title: "G1_2", taskType: .oneOff, createdAt: now.addingTimeInterval(1), workflowState: .doing),
            Task(id: "g2_1", projectId: "p1", title: "G2_1", taskType: .oneOff, dueDate: now.addingTimeInterval(-3600), createdAt: now),
            Task(id: "g2_2", projectId: "p1", title: "G2_2", taskType: .oneOff, dueDate: now.addingTimeInterval(-7200), createdAt: now),
            Task(id: "g5_1", projectId: "p1", title: "G5_1", taskType: .dailyRecurring, createdAt: now),
            Task(id: "g6_1", projectId: "p1", title: "G6_1", taskType: .oneOff, createdAt: now),
        ]

        // When: Top 3
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: tasks.shuffled(),
            completionLogs: [],
            topN: 3,
            now: now
        )

        // Then: Top 3는 G1, G2에서 가져옴
        XCTAssertEqual(summary.displayList.count, 3)
        XCTAssertTrue(summary.displayList.allSatisfy { $0.id.hasPrefix("g1") || $0.id.hasPrefix("g2") })
        XCTAssertEqual(summary.counters.outstandingTotal, 6)
    }

    // MARK: - H. CompleteNextTask 정합성 테스트

    /// M6-7-H1: displayList[0]이 CompleteNextTask 대상과 항상 일치
    func testIntegration_CompleteNextTask_Consistency() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = createDate()

        let tasks = [
            Task(id: "doing", projectId: "p1", title: "Doing", taskType: .oneOff, createdAt: now, workflowState: .doing),
            Task(id: "overdue", projectId: "p1", title: "Overdue", taskType: .oneOff, dueDate: now.addingTimeInterval(-3600), createdAt: now),
            Task(id: "p1", projectId: "p1", title: "P1", taskType: .oneOff, priority: .p1, createdAt: now),
            Task(id: "blocked", projectId: "p1", title: "Blocked", taskType: .oneOff, createdAt: now, blockedByTaskIds: ["doing"]),
        ]

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: tasks,
            completionLogs: [],
            now: now
        )

        // Then: displayList[0]이 존재하고, blocked 태스크가 아님
        XCTAssertEqual(summary.displayList.first?.id, "doing")
        XCTAssertFalse(summary.displayList.contains { $0.id == "blocked" })
    }

    /// M6-7-H2: blocked 태스크만 있을 때 displayList 비어있음
    func testIntegration_OnlyBlockedTasks_NoCompleteTarget() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let blockedTask = Task(
            id: "blocked",
            projectId: "p1",
            title: "Blocked",
            taskType: .oneOff,
            blockedByTaskIds: ["nonexistent"]
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [blockedTask],
            completionLogs: []
        )

        // Then
        XCTAssertTrue(summary.displayList.isEmpty)
        XCTAssertEqual(summary.counters.outstandingTotal, 0)
    }
}
