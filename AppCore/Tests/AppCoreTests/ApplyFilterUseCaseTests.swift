import XCTest
@testable import AppCore

final class ApplyFilterUseCaseTests: XCTestCase {

    private var useCase: ApplyFilterUseCase!
    private var testProject: Project!
    private var dateKey: DateKey!

    override func setUp() {
        super.setUp()
        useCase = ApplyFilterUseCase()
        testProject = Project(
            id: "proj-1",
            title: "Test Project",
            startDate: Date()
        )
        dateKey = DateKey.today()
    }

    // MARK: - Empty Filter Tests

    func test_emptyFilter_returnsActiveTasks() {
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1")
        let task2 = Task(
            id: "t2",
            projectId: "proj-1",
            title: "Task 2",
            workflowState: .done
        )

        let result = useCase.execute(
            filter: .empty,
            tasks: [task1, task2],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        // done 상태는 기본적으로 제외
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t1")
    }

    // MARK: - Project Filter Tests

    func test_projectFilter_filtersCorrectly() {
        let proj2 = Project(id: "proj-2", title: "Project 2", startDate: Date())
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1")
        let task2 = Task(id: "t2", projectId: "proj-2", title: "Task 2")

        let filter = FilterDefinition.project("proj-1")
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2],
            projects: [testProject, proj2],
            completionLogs: [],
            dateKey: dateKey
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t1")
    }

    // MARK: - Tag Filter Tests

    func test_tagFilter_filtersCorrectly() {
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1", tagIds: ["tag-1"])
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", tagIds: ["tag-2"])
        let task3 = Task(id: "t3", projectId: "proj-1", title: "Task 3", tagIds: ["tag-1", "tag-2"])

        let filter = FilterDefinition.tag("tag-1")
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2, task3],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.id == "t1" })
        XCTAssertTrue(result.contains { $0.id == "t3" })
    }

    // MARK: - Priority Filter Tests

    func test_priorityAtLeastFilter_filtersCorrectly() {
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1", priority: .p1)
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", priority: .p2)
        let task3 = Task(id: "t3", projectId: "proj-1", title: "Task 3", priority: .p4)

        let filter = FilterDefinition.priorityAtLeast(.p2)
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2, task3],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        // P1, P2만 포함 (P1이 가장 높음)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.id == "t1" })
        XCTAssertTrue(result.contains { $0.id == "t2" })
    }

    func test_priorityAtMostFilter_filtersCorrectly() {
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1", priority: .p1)
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", priority: .p3)
        let task3 = Task(id: "t3", projectId: "proj-1", title: "Task 3", priority: .p4)

        let filter = FilterDefinition(priorityAtMost: .p3)
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2, task3],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        // P3, P4만 포함
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.id == "t2" })
        XCTAssertTrue(result.contains { $0.id == "t3" })
    }

    // MARK: - State Filter Tests

    func test_stateFilter_filtersCorrectly() {
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1", workflowState: .todo)
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", workflowState: .doing)
        let task3 = Task(id: "t3", projectId: "proj-1", title: "Task 3", workflowState: .done)

        let filter = FilterDefinition(stateIn: [.doing])
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2, task3],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t2")
    }

    // MARK: - Due Range Filter Tests

    func test_todayDueFilter_filtersCorrectly() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1", dueDate: today)
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", dueDate: tomorrow)
        let task3 = Task(id: "t3", projectId: "proj-1", title: "Task 3")

        let filter = FilterDefinition.due(.today)
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2, task3],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t1")
    }

    func test_overdueDueFilter_filtersCorrectly() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1", dueDate: yesterday)
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", dueDate: tomorrow)

        let filter = FilterDefinition.due(.overdue)
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t1")
    }

    func test_noDueDateFilter_filtersCorrectly() {
        let today = Date()
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1", dueDate: today)
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2")

        let filter = FilterDefinition.due(.none)
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t2")
    }

    // MARK: - Recurring Filter Tests

    func test_recurringFilter_includesOnlyRecurring() {
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1", taskType: .oneOff)
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", taskType: .dailyRecurring)

        let filter = FilterDefinition(includeRecurring: true)
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t2")
    }

    func test_recurringFilter_excludesRecurring() {
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1", taskType: .oneOff)
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", taskType: .dailyRecurring)

        let filter = FilterDefinition(includeRecurring: false)
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t1")
    }

    // MARK: - Blocked Filter Tests

    func test_excludeBlocked_filtersBlockedTasks() {
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1")
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", blockedByTaskIds: ["t1"])

        let filter = FilterDefinition(excludeBlocked: true)
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        // t2는 t1에 의해 차단됨 (t1이 미완료)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t1")
    }

    func test_excludeBlocked_includesUnblockedAfterCompletion() {
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1")
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", blockedByTaskIds: ["t1"])

        // t1 완료 로그
        let log = CompletionLog(taskId: "t1", occurrenceKey: "once")

        let filter = FilterDefinition(excludeBlocked: true)
        let result = useCase.execute(
            filter: filter,
            tasks: [task1, task2],
            projects: [testProject],
            completionLogs: [log],
            dateKey: dateKey
        )

        // t1은 완료되어 결과에서 제외, t2는 더 이상 차단되지 않음
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "t2")
    }

    // MARK: - Completed Task Exclusion Tests

    func test_completedOneOff_excluded() {
        let task = Task(id: "t1", projectId: "proj-1", title: "Task 1", taskType: .oneOff)
        let log = CompletionLog(taskId: "t1", occurrenceKey: "once")

        let result = useCase.execute(
            filter: .empty,
            tasks: [task],
            projects: [testProject],
            completionLogs: [log],
            dateKey: dateKey
        )

        XCTAssertTrue(result.isEmpty)
    }

    func test_completedHabitReset_excludedToday() {
        let task = Task(id: "t1", projectId: "proj-1", title: "Task 1", taskType: .dailyRecurring)
        let log = CompletionLog(taskId: "t1", occurrenceKey: dateKey.value)

        let result = useCase.execute(
            filter: .empty,
            tasks: [task],
            projects: [testProject],
            completionLogs: [log],
            dateKey: dateKey
        )

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Archived Project Exclusion Tests

    func test_archivedProject_tasksExcluded() {
        let archivedProject = Project(
            id: "proj-archived",
            title: "Archived",
            startDate: Date(),
            status: .archived
        )
        let task = Task(id: "t1", projectId: "proj-archived", title: "Task 1")

        let result = useCase.execute(
            filter: .empty,
            tasks: [task],
            projects: [archivedProject],
            completionLogs: [],
            dateKey: dateKey
        )

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Metadata Tests

    func test_executeWithMetadata_returnsCorrectCounts() {
        let task1 = Task(id: "t1", projectId: "proj-1", title: "Task 1", priority: .p1)
        let task2 = Task(id: "t2", projectId: "proj-1", title: "Task 2", priority: .p4)
        let task3 = Task(id: "t3", projectId: "proj-1", title: "Task 3", priority: .p4)

        let filter = FilterDefinition.priorityAtLeast(.p1)
        let (tasks, metadata) = useCase.executeWithMetadata(
            filter: filter,
            tasks: [task1, task2, task3],
            projects: [testProject],
            completionLogs: [],
            dateKey: dateKey
        )

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(metadata.totalCount, 3)
        XCTAssertEqual(metadata.filteredCount, 1)
        XCTAssertEqual(metadata.excludedCount, 2)
    }
}
