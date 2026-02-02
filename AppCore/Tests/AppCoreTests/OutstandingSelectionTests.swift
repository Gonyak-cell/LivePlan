import XCTest
@testable import AppCore

/// 잠금화면 선정 알고리즘 테스트
/// - testing.md B6, 우선순위 테스트 준수
final class OutstandingSelectionTests: XCTestCase {

    private var computer: OutstandingComputer!

    override func setUp() {
        super.setUp()
        computer = OutstandingComputer()
    }

    // MARK: - B6: pinned 유무 폴백

    func testB6_PinnedFirst_WithPinnedProject() {
        // Given: 핀 프로젝트 있음
        let pinnedProject = Project(id: "pinned", title: "Pinned Project", startDate: Date())
        let otherProject = Project(id: "other", title: "Other Project", startDate: Date())
        let pinnedTask = Task(id: "t1", projectId: "pinned", title: "Pinned Task", taskType: .oneOff)
        let otherTask = Task(id: "t2", projectId: "other", title: "Other Task", taskType: .oneOff)

        // When: pinnedFirst 정책
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .pinnedFirst(projectId: "pinned"),
            privacyMode: .visible,
            projects: [pinnedProject, otherProject],
            tasks: [pinnedTask, otherTask],
            completionLogs: []
        )

        // Then: 핀 프로젝트 태스크만 포함
        XCTAssertEqual(summary.counters.outstandingTotal, 1)
        XCTAssertEqual(summary.displayList.first?.id, "t1")
    }

    func testB6_PinnedFirst_NoPinned_FallbackToTodayOverview() {
        // Given: 핀 프로젝트 없음
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Task", taskType: .oneOff)

        // When: pinnedFirst(nil)
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .pinnedFirst(projectId: nil),
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: []
        )

        // Then: 전체 프로젝트로 폴백 + 폴백 사유 기록
        XCTAssertEqual(summary.counters.outstandingTotal, 1)
        XCTAssertEqual(summary.fallbackReason, .noPinnedProject)
    }

    func testB6_PinnedFirst_ArchivedPinned_Fallback() {
        // Given: 핀 프로젝트가 archived
        let archivedPinned = Project(
            id: "pinned",
            title: "Archived",
            startDate: Date(),
            status: .archived
        )
        let activeProject = Project(id: "active", title: "Active", startDate: Date())
        let task = Task(id: "t1", projectId: "active", title: "Task", taskType: .oneOff)

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .pinnedFirst(projectId: "pinned"),
            privacyMode: .visible,
            projects: [archivedPinned, activeProject],
            tasks: [task],
            completionLogs: []
        )

        // Then: 폴백 + 사유 기록
        XCTAssertEqual(summary.fallbackReason, .pinnedProjectArchived)
    }

    func testB6_PinnedFirst_CompletedPinned_Fallback() {
        // Given: 핀 프로젝트가 completed
        let completedPinned = Project(
            id: "pinned",
            title: "Completed",
            startDate: Date(),
            status: .completed
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .pinnedFirst(projectId: "pinned"),
            privacyMode: .visible,
            projects: [completedPinned],
            tasks: [],
            completionLogs: []
        )

        // Then
        XCTAssertEqual(summary.fallbackReason, .pinnedProjectCompleted)
    }

    // MARK: - Priority Groups (Phase 1)

    func testPriorityGroup_OverdueFirst() {
        // Given: overdue + dueSoon + normal
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        let overdueTask = Task(
            id: "overdue",
            projectId: "p1",
            title: "Overdue",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(-3600) // 1시간 전
        )
        let dueSoonTask = Task(
            id: "dueSoon",
            projectId: "p1",
            title: "Due Soon",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(3600) // 1시간 후
        )
        let normalTask = Task(
            id: "normal",
            projectId: "p1",
            title: "Normal",
            taskType: .oneOff
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [normalTask, dueSoonTask, overdueTask], // 순서 섞어서
            completionLogs: [],
            now: now
        )

        // Then: overdue > dueSoon > normal 순서
        XCTAssertEqual(summary.displayList.count, 3)
        XCTAssertEqual(summary.displayList[0].id, "overdue")
        XCTAssertEqual(summary.displayList[1].id, "dueSoon")
        XCTAssertEqual(summary.displayList[2].id, "normal")
    }

    func testPriorityGroup_DailyRecurringBeforeNormal() {
        // Given: dailyRecurring + oneOff (둘 다 dueDate 없음)
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let recurringTask = Task(
            id: "recurring",
            projectId: "p1",
            title: "Daily",
            taskType: .dailyRecurring
        )
        let oneOffTask = Task(
            id: "oneOff",
            projectId: "p1",
            title: "OneOff",
            taskType: .oneOff
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [oneOffTask, recurringTask], // 순서 섞어서
            completionLogs: []
        )

        // Then: dailyRecurring이 먼저
        XCTAssertEqual(summary.displayList[0].id, "recurring")
        XCTAssertEqual(summary.displayList[1].id, "oneOff")
    }

    // MARK: - Tie-breaker

    func testTiebreaker_DueDateThenCreatedAt() {
        // Given: 같은 그룹, 다른 dueDate
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        let task1 = Task(
            id: "t1",
            projectId: "p1",
            title: "Later Due",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(7200), // 2시간 후
            createdAt: now.addingTimeInterval(-3600) // 먼저 생성
        )
        let task2 = Task(
            id: "t2",
            projectId: "p1",
            title: "Earlier Due",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(3600), // 1시간 후
            createdAt: now // 나중 생성
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task1, task2],
            completionLogs: [],
            now: now
        )

        // Then: dueDate가 빠른 것이 먼저
        XCTAssertEqual(summary.displayList[0].id, "t2")
        XCTAssertEqual(summary.displayList[1].id, "t1")
    }

    func testTiebreaker_CreatedAtWhenNoDueDate() {
        // Given: dueDate 없음, 다른 createdAt
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        let task1 = Task(
            id: "t1",
            projectId: "p1",
            title: "Later Created",
            taskType: .oneOff,
            createdAt: now
        )
        let task2 = Task(
            id: "t2",
            projectId: "p1",
            title: "Earlier Created",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(-3600)
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task1, task2],
            completionLogs: []
        )

        // Then: createdAt이 빠른 것이 먼저
        XCTAssertEqual(summary.displayList[0].id, "t2")
        XCTAssertEqual(summary.displayList[1].id, "t1")
    }

    /// M6-3: 동일 그룹 내 priority 정렬 (P1→P4)
    func testTiebreaker_PriorityWithinSameGroup() {
        // Given: 같은 그룹(G6), dueDate 없음, 다른 priority
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        let taskP4 = Task(
            id: "t_p4",
            projectId: "p1",
            title: "Low Priority",
            taskType: .oneOff,
            priority: .p4,
            createdAt: now.addingTimeInterval(-3600) // 먼저 생성 (createdAt으로는 우선)
        )
        let taskP2 = Task(
            id: "t_p2",
            projectId: "p1",
            title: "Medium Priority",
            taskType: .oneOff,
            priority: .p2,
            createdAt: now // 나중 생성
        )
        let taskP1 = Task(
            id: "t_p1",
            projectId: "p1",
            title: "High Priority",
            taskType: .oneOff,
            priority: .p1, // G4에 속하므로 그룹이 다름 - 가장 먼저
            createdAt: now.addingTimeInterval(3600) // 가장 나중 생성
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [taskP4, taskP2, taskP1], // 순서 섞어서
            completionLogs: [],
            now: now
        )

        // Then: P1(G4) > P2(G6) > P4(G6) 순서
        // P1은 G4(priority P1 그룹)이므로 가장 먼저
        // P2와 P4는 둘 다 G6이므로 priority 순서로 P2 > P4
        XCTAssertEqual(summary.displayList.count, 3)
        XCTAssertEqual(summary.displayList[0].id, "t_p1")
        XCTAssertEqual(summary.displayList[1].id, "t_p2")
        XCTAssertEqual(summary.displayList[2].id, "t_p4")
    }

    /// M6-3: 동일 그룹/dueDate 내 priority 정렬 (dueDate 동일)
    func testTiebreaker_PriorityWithSameDueDate() {
        // Given: 같은 그룹(G3 dueSoon), 같은 dueDate, 다른 priority
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()
        let sameDueDate = now.addingTimeInterval(3600) // 1시간 후 (dueSoon)

        let taskP3 = Task(
            id: "t_p3",
            projectId: "p1",
            title: "P3 Task",
            taskType: .oneOff,
            priority: .p3,
            dueDate: sameDueDate,
            createdAt: now.addingTimeInterval(-7200) // 가장 먼저 생성
        )
        let taskP1 = Task(
            id: "t_p1_due",
            projectId: "p1",
            title: "P1 Task",
            taskType: .oneOff,
            priority: .p1,
            dueDate: sameDueDate,
            createdAt: now // 중간 생성
        )
        let taskP2 = Task(
            id: "t_p2_due",
            projectId: "p1",
            title: "P2 Task",
            taskType: .oneOff,
            priority: .p2,
            dueDate: sameDueDate,
            createdAt: now.addingTimeInterval(-3600)
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [taskP3, taskP1, taskP2], // 순서 섞어서
            completionLogs: [],
            now: now
        )

        // Then: 모두 G3(dueSoon), dueDate 동일 → priority 순서로 P1 > P2 > P3
        XCTAssertEqual(summary.displayList.count, 3)
        XCTAssertEqual(summary.displayList[0].id, "t_p1_due")
        XCTAssertEqual(summary.displayList[1].id, "t_p2_due")
        XCTAssertEqual(summary.displayList[2].id, "t_p3")
    }

    /// M6-3: ID 기반 결정론 tie-breaker (모든 조건 동일)
    func testTiebreaker_IdBasedDeterminism() {
        // Given: 모든 조건 동일 (같은 그룹, dueDate 없음, 같은 priority, 같은 createdAt)
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        let taskB = Task(
            id: "b_task",
            projectId: "p1",
            title: "Task B",
            taskType: .oneOff,
            priority: .p4,
            createdAt: now
        )
        let taskA = Task(
            id: "a_task",
            projectId: "p1",
            title: "Task A",
            taskType: .oneOff,
            priority: .p4,
            createdAt: now
        )
        let taskC = Task(
            id: "c_task",
            projectId: "p1",
            title: "Task C",
            taskType: .oneOff,
            priority: .p4,
            createdAt: now
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [taskB, taskA, taskC], // 순서 섞어서
            completionLogs: [],
            now: now
        )

        // Then: ID 알파벳 순서로 결정론적 정렬 (a < b < c)
        XCTAssertEqual(summary.displayList.count, 3)
        XCTAssertEqual(summary.displayList[0].id, "a_task")
        XCTAssertEqual(summary.displayList[1].id, "b_task")
        XCTAssertEqual(summary.displayList[2].id, "c_task")
    }

    // MARK: - Top N

    func testTopN_LimitedTo3() {
        // Given: 5개 태스크
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let tasks = (1...5).map { i in
            Task(id: "t\(i)", projectId: "p1", title: "Task \(i)", taskType: .oneOff)
        }

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: tasks,
            completionLogs: [],
            topN: 3
        )

        // Then: displayList는 3개, counters.outstandingTotal은 5
        XCTAssertEqual(summary.displayList.count, 3)
        XCTAssertEqual(summary.counters.outstandingTotal, 5)
    }

    // MARK: - Counters

    func testCounters_OverdueAndDueSoon() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        let overdueTask = Task(
            id: "overdue",
            projectId: "p1",
            title: "Overdue",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(-3600)
        )
        let dueSoonTask = Task(
            id: "dueSoon",
            projectId: "p1",
            title: "Due Soon",
            taskType: .oneOff,
            dueDate: now.addingTimeInterval(3600)
        )
        let normalTask = Task(
            id: "normal",
            projectId: "p1",
            title: "Normal",
            taskType: .oneOff
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [overdueTask, dueSoonTask, normalTask],
            completionLogs: [],
            now: now
        )

        // Then
        XCTAssertEqual(summary.counters.outstandingTotal, 3)
        XCTAssertEqual(summary.counters.overdueCount, 1)
        XCTAssertEqual(summary.counters.dueSoonCount, 1)
    }

    func testCounters_RecurringDoneAndTotal() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let todayKey = DateKey.today()

        let recurring1 = Task(id: "r1", projectId: "p1", title: "R1", taskType: .dailyRecurring)
        let recurring2 = Task(id: "r2", projectId: "p1", title: "R2", taskType: .dailyRecurring)
        let log = CompletionLog.forDailyRecurring(taskId: "r1", dateKey: todayKey.value)

        // When
        let summary = computer.compute(
            dateKey: todayKey,
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [recurring1, recurring2],
            completionLogs: [log]
        )

        // Then
        XCTAssertEqual(summary.counters.recurringTotal, 2)
        XCTAssertEqual(summary.counters.recurringDone, 1)
        XCTAssertEqual(summary.counters.outstandingTotal, 1) // r2만
    }

    // MARK: - Filter: Archived/Completed Projects

    func testFilter_ExcludesArchivedProject() {
        // Given
        let activeProject = Project(id: "active", title: "Active", startDate: Date())
        let archivedProject = Project(
            id: "archived",
            title: "Archived",
            startDate: Date(),
            status: .archived
        )
        let activeTask = Task(id: "t1", projectId: "active", title: "Active Task", taskType: .oneOff)
        let archivedTask = Task(id: "t2", projectId: "archived", title: "Archived Task", taskType: .oneOff)

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [activeProject, archivedProject],
            tasks: [activeTask, archivedTask],
            completionLogs: []
        )

        // Then: archived 프로젝트의 태스크 제외
        XCTAssertEqual(summary.counters.outstandingTotal, 1)
        XCTAssertEqual(summary.displayList.first?.id, "t1")
    }

    // MARK: - Empty State

    func testEmptyState_NoTasks() {
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
        XCTAssertTrue(summary.displayList.isEmpty)
        XCTAssertEqual(summary.counters.outstandingTotal, 0)
        XCTAssertEqual(summary.fallbackReason, .noTasks)
    }

    func testEmptyState_AllCompleted() {
        // Given
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Task", taskType: .oneOff)
        let log = CompletionLog.forOneOff(taskId: "t1")

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: [log]
        )

        // Then
        XCTAssertTrue(summary.displayList.isEmpty)
        XCTAssertEqual(summary.counters.outstandingTotal, 0)
        XCTAssertEqual(summary.fallbackReason, .allCompleted)
    }

    // MARK: - M6-1: Blocked Tasks Filtering

    func testFilter_ExcludesBlockedTasks() {
        // Given: blocked 태스크 + 일반 태스크
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let blockerTask = Task(
            id: "blocker",
            projectId: "p1",
            title: "Blocker Task",
            taskType: .oneOff
        )
        let blockedTask = Task(
            id: "blocked",
            projectId: "p1",
            title: "Blocked Task",
            taskType: .oneOff,
            blockedByTaskIds: ["blocker"]
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [blockerTask, blockedTask],
            completionLogs: []
        )

        // Then: blocked 태스크가 displayList에서 제외됨
        XCTAssertEqual(summary.displayList.count, 1)
        XCTAssertEqual(summary.displayList.first?.id, "blocker")
        XCTAssertEqual(summary.counters.outstandingTotal, 1)
    }

    func testFilter_BlockedTasksNotInTop1() {
        // Given: blocked 태스크만 존재
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let blockedTask = Task(
            id: "blocked",
            projectId: "p1",
            title: "Blocked Task",
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

        // Then: displayList가 비어있음 (CompleteNextTask 대상 없음)
        XCTAssertTrue(summary.displayList.isEmpty)
        XCTAssertEqual(summary.counters.outstandingTotal, 0)
        XCTAssertEqual(summary.fallbackReason, .allCompleted)
    }

    func testFilter_BlockerTaskAppears() {
        // Given: blocker가 완료되지 않은 상태에서 blocked 태스크와 함께
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()
        let blockerTask = Task(
            id: "blocker",
            projectId: "p1",
            title: "Blocker",
            taskType: .oneOff,
            createdAt: now
        )
        let blockedTask = Task(
            id: "blocked",
            projectId: "p1",
            title: "Blocked",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(-3600), // 먼저 생성되었지만
            blockedByTaskIds: ["blocker"]
        )
        let normalTask = Task(
            id: "normal",
            projectId: "p1",
            title: "Normal",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(3600) // 나중 생성
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [blockedTask, blockerTask, normalTask],
            completionLogs: []
        )

        // Then: blocker와 normal만 노출, blocked는 제외
        XCTAssertEqual(summary.displayList.count, 2)
        let displayIds = summary.displayList.map { $0.id }
        XCTAssertTrue(displayIds.contains("blocker"))
        XCTAssertTrue(displayIds.contains("normal"))
        XCTAssertFalse(displayIds.contains("blocked"))
        XCTAssertEqual(summary.counters.outstandingTotal, 2)
    }

    // MARK: - M6-4: Extended Counters (p1Count, doingCount, blockedCount)

    func testCounters_P1Count() {
        // Given: P1, P2, P4 태스크
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let taskP1_1 = Task(
            id: "t_p1_1",
            projectId: "p1",
            title: "P1 Task 1",
            taskType: .oneOff,
            priority: .p1
        )
        let taskP1_2 = Task(
            id: "t_p1_2",
            projectId: "p1",
            title: "P1 Task 2",
            taskType: .oneOff,
            priority: .p1
        )
        let taskP2 = Task(
            id: "t_p2",
            projectId: "p1",
            title: "P2 Task",
            taskType: .oneOff,
            priority: .p2
        )
        let taskP4 = Task(
            id: "t_p4",
            projectId: "p1",
            title: "P4 Task",
            taskType: .oneOff,
            priority: .p4
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [taskP1_1, taskP1_2, taskP2, taskP4],
            completionLogs: []
        )

        // Then: P1 카운트는 2
        XCTAssertEqual(summary.counters.p1Count, 2)
        XCTAssertEqual(summary.counters.outstandingTotal, 4)
    }

    func testCounters_DoingCount() {
        // Given: doing 상태 태스크 + todo 상태 태스크
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let doingTask1 = Task(
            id: "doing1",
            projectId: "p1",
            title: "Doing Task 1",
            taskType: .oneOff,
            workflowState: .doing
        )
        let doingTask2 = Task(
            id: "doing2",
            projectId: "p1",
            title: "Doing Task 2",
            taskType: .oneOff,
            workflowState: .doing
        )
        let todoTask = Task(
            id: "todo",
            projectId: "p1",
            title: "Todo Task",
            taskType: .oneOff,
            workflowState: .todo
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [doingTask1, doingTask2, todoTask],
            completionLogs: []
        )

        // Then: doing 카운트는 2
        XCTAssertEqual(summary.counters.doingCount, 2)
        XCTAssertEqual(summary.counters.outstandingTotal, 3)
    }

    func testCounters_BlockedCount() {
        // Given: blocked 태스크 + 일반 태스크
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let blockerTask = Task(
            id: "blocker",
            projectId: "p1",
            title: "Blocker",
            taskType: .oneOff
        )
        let blockedTask1 = Task(
            id: "blocked1",
            projectId: "p1",
            title: "Blocked 1",
            taskType: .oneOff,
            blockedByTaskIds: ["blocker"]
        )
        let blockedTask2 = Task(
            id: "blocked2",
            projectId: "p1",
            title: "Blocked 2",
            taskType: .oneOff,
            blockedByTaskIds: ["blocker"]
        )
        let normalTask = Task(
            id: "normal",
            projectId: "p1",
            title: "Normal",
            taskType: .oneOff
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [blockerTask, blockedTask1, blockedTask2, normalTask],
            completionLogs: []
        )

        // Then: blocked 카운트는 2 (blocked 태스크는 displayList에서 제외되지만 카운터에는 포함)
        XCTAssertEqual(summary.counters.blockedCount, 2)
        // outstandingTotal은 blocked 태스크 제외
        XCTAssertEqual(summary.counters.outstandingTotal, 2) // blocker + normal
    }

    func testCounters_AllExtendedCounters() {
        // Given: P1 + doing + blocked 조합
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        // P1 + doing 태스크
        let p1DoingTask = Task(
            id: "p1_doing",
            projectId: "p1",
            title: "P1 Doing",
            taskType: .oneOff,
            priority: .p1,
            workflowState: .doing
        )
        // P1 + todo 태스크
        let p1Task = Task(
            id: "p1_todo",
            projectId: "p1",
            title: "P1 Todo",
            taskType: .oneOff,
            priority: .p1
        )
        // doing 태스크 (P4)
        let doingTask = Task(
            id: "doing",
            projectId: "p1",
            title: "Doing",
            taskType: .oneOff,
            workflowState: .doing
        )
        // blocker
        let blockerTask = Task(
            id: "blocker",
            projectId: "p1",
            title: "Blocker",
            taskType: .oneOff
        )
        // blocked 태스크
        let blockedTask = Task(
            id: "blocked",
            projectId: "p1",
            title: "Blocked",
            taskType: .oneOff,
            blockedByTaskIds: ["blocker"]
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [p1DoingTask, p1Task, doingTask, blockerTask, blockedTask],
            completionLogs: [],
            now: now
        )

        // Then: 각 카운터 확인
        XCTAssertEqual(summary.counters.p1Count, 2) // p1_doing, p1_todo
        XCTAssertEqual(summary.counters.doingCount, 2) // p1_doing, doing
        XCTAssertEqual(summary.counters.blockedCount, 1) // blocked
        XCTAssertEqual(summary.counters.outstandingTotal, 4) // blocked 제외
    }

    func testCounters_P1CountWithCompletedTasks() {
        // Given: P1 태스크 중 일부 완료
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let taskP1_completed = Task(
            id: "p1_completed",
            projectId: "p1",
            title: "P1 Completed",
            taskType: .oneOff,
            priority: .p1
        )
        let taskP1_pending = Task(
            id: "p1_pending",
            projectId: "p1",
            title: "P1 Pending",
            taskType: .oneOff,
            priority: .p1
        )
        let log = CompletionLog.forOneOff(taskId: "p1_completed")

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [taskP1_completed, taskP1_pending],
            completionLogs: [log]
        )

        // Then: 완료된 P1은 p1Count에서 제외
        XCTAssertEqual(summary.counters.p1Count, 1)
        XCTAssertEqual(summary.counters.outstandingTotal, 1)
    }

    // MARK: - M6-5: DisplayTask Extensions (isDoing, priority, isP1)

    /// M6-5: DisplayTask.isDoing 플래그가 정확히 채워지는지 검증
    func testDisplayTask_IsDoingFlagPopulated() {
        // Given: doing 상태 태스크 + todo 상태 태스크
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        let doingTask = Task(
            id: "doing",
            projectId: "p1",
            title: "Doing Task",
            taskType: .oneOff,
            createdAt: now,
            workflowState: .doing
        )
        let todoTask = Task(
            id: "todo",
            projectId: "p1",
            title: "Todo Task",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(-3600),
            workflowState: .todo
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [todoTask, doingTask], // 순서 섞어서
            completionLogs: [],
            now: now
        )

        // Then: doing 태스크가 먼저(G1), isDoing 플래그 검증
        XCTAssertEqual(summary.displayList.count, 2)
        XCTAssertEqual(summary.displayList[0].id, "doing")
        XCTAssertTrue(summary.displayList[0].isDoing)
        XCTAssertEqual(summary.displayList[1].id, "todo")
        XCTAssertFalse(summary.displayList[1].isDoing)
    }

    /// M6-5: DisplayTask.priority 필드가 정확히 채워지는지 검증
    func testDisplayTask_PriorityFieldPopulated() {
        // Given: 다양한 priority 태스크
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        let taskP1 = Task(
            id: "t_p1",
            projectId: "p1",
            title: "P1 Task",
            taskType: .oneOff,
            createdAt: now,
            priority: .p1
        )
        let taskP2 = Task(
            id: "t_p2",
            projectId: "p1",
            title: "P2 Task",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(-3600),
            priority: .p2
        )
        let taskP3 = Task(
            id: "t_p3",
            projectId: "p1",
            title: "P3 Task",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(-7200),
            priority: .p3
        )
        let taskP4 = Task(
            id: "t_p4",
            projectId: "p1",
            title: "P4 Task",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(-10800),
            priority: .p4
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [taskP4, taskP2, taskP1, taskP3], // 순서 섞어서
            completionLogs: [],
            now: now
        )

        // Then: priority 필드가 각 DisplayTask에 정확히 할당됨
        XCTAssertEqual(summary.displayList.count, 4)

        // P1이 G4 그룹으로 먼저
        XCTAssertEqual(summary.displayList[0].id, "t_p1")
        XCTAssertEqual(summary.displayList[0].priority, .p1)

        // 나머지는 G6 그룹, priority 순서로 정렬
        XCTAssertEqual(summary.displayList[1].id, "t_p2")
        XCTAssertEqual(summary.displayList[1].priority, .p2)

        XCTAssertEqual(summary.displayList[2].id, "t_p3")
        XCTAssertEqual(summary.displayList[2].priority, .p3)

        XCTAssertEqual(summary.displayList[3].id, "t_p4")
        XCTAssertEqual(summary.displayList[3].priority, .p4)
    }

    /// M6-5: DisplayTask.isP1 계산 프로퍼티 검증
    func testDisplayTask_IsP1ComputedProperty() {
        // Given: P1 + P2 + P4 태스크
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        let taskP1 = Task(
            id: "t_p1",
            projectId: "p1",
            title: "P1 Task",
            taskType: .oneOff,
            createdAt: now,
            priority: .p1
        )
        let taskP2 = Task(
            id: "t_p2",
            projectId: "p1",
            title: "P2 Task",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(-3600),
            priority: .p2
        )
        let taskP4 = Task(
            id: "t_p4",
            projectId: "p1",
            title: "P4 Task",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(-7200),
            priority: .p4
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [taskP4, taskP2, taskP1],
            completionLogs: [],
            now: now
        )

        // Then: isP1은 P1인 경우에만 true
        XCTAssertEqual(summary.displayList.count, 3)
        XCTAssertTrue(summary.displayList[0].isP1)   // P1
        XCTAssertFalse(summary.displayList[1].isP1)  // P2
        XCTAssertFalse(summary.displayList[2].isP1)  // P4
    }

    /// M6-5: DisplayTask isDoing + priority 복합 검증
    func testDisplayTask_DoingWithPriority() {
        // Given: doing 상태 + 다양한 priority 조합
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        // P1 + doing
        let doingP1 = Task(
            id: "doing_p1",
            projectId: "p1",
            title: "Doing P1",
            taskType: .oneOff,
            createdAt: now,
            priority: .p1,
            workflowState: .doing
        )
        // P4 + doing
        let doingP4 = Task(
            id: "doing_p4",
            projectId: "p1",
            title: "Doing P4",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(-3600),
            priority: .p4,
            workflowState: .doing
        )
        // P1 + todo
        let todoP1 = Task(
            id: "todo_p1",
            projectId: "p1",
            title: "Todo P1",
            taskType: .oneOff,
            createdAt: now.addingTimeInterval(-7200),
            priority: .p1,
            workflowState: .todo
        )

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [todoP1, doingP4, doingP1],
            completionLogs: [],
            now: now
        )

        // Then: G1(doing) 먼저, 그 안에서 priority 순서
        XCTAssertEqual(summary.displayList.count, 3)

        // doing 태스크들이 먼저 (G1), priority 순서로 P1 > P4
        XCTAssertEqual(summary.displayList[0].id, "doing_p1")
        XCTAssertTrue(summary.displayList[0].isDoing)
        XCTAssertEqual(summary.displayList[0].priority, .p1)
        XCTAssertTrue(summary.displayList[0].isP1)

        XCTAssertEqual(summary.displayList[1].id, "doing_p4")
        XCTAssertTrue(summary.displayList[1].isDoing)
        XCTAssertEqual(summary.displayList[1].priority, .p4)
        XCTAssertFalse(summary.displayList[1].isP1)

        // todo P1은 G4 그룹
        XCTAssertEqual(summary.displayList[2].id, "todo_p1")
        XCTAssertFalse(summary.displayList[2].isDoing)
        XCTAssertEqual(summary.displayList[2].priority, .p1)
        XCTAssertTrue(summary.displayList[2].isP1)
    }

    /// M6-5: DisplayTask 필드가 프라이버시 모드에서도 유지되는지 검증
    func testDisplayTask_FieldsPreservedWithPrivacyMode() {
        // Given: doing + P1 태스크
        let project = Project(id: "p1", title: "Project", startDate: Date())
        let now = Date()

        let doingP1 = Task(
            id: "doing_p1",
            projectId: "p1",
            title: "Secret Task",
            taskType: .oneOff,
            createdAt: now,
            priority: .p1,
            workflowState: .doing
        )

        // When: masked 프라이버시 모드
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .masked,
            projects: [project],
            tasks: [doingP1],
            completionLogs: [],
            now: now
        )

        // Then: 제목은 마스킹되지만 isDoing/priority/isP1 필드는 유지됨
        XCTAssertEqual(summary.displayList.count, 1)
        let displayTask = summary.displayList[0]

        XCTAssertEqual(displayTask.displayTitle, "할 일 1") // 마스킹됨
        XCTAssertTrue(displayTask.isDoing)                  // 유지
        XCTAssertEqual(displayTask.priority, .p1)           // 유지
        XCTAssertTrue(displayTask.isP1)                     // 유지
    }
}
