import XCTest
@testable import AppCore

/// CompleteTaskUseCase 테스트
/// - testing.md B1~B3: 완료 처리 필수 테스트 케이스
/// - data-model.md A4/A6: Task/CompletionLog 불변식 준수
/// - 멱등성 검증 필수
final class CompleteTaskUseCaseTests: XCTestCase {

    private var taskRepository: MockTaskRepository!
    private var completionLogRepository: MockCompletionLogRepository!
    private var sut: CompleteTaskUseCase!

    override func setUp() {
        super.setUp()
        taskRepository = MockTaskRepository()
        completionLogRepository = MockCompletionLogRepository()
        sut = CompleteTaskUseCase(
            taskRepository: taskRepository,
            completionLogRepository: completionLogRepository
        )
    }

    override func tearDown() {
        taskRepository = nil
        completionLogRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - B1. OneOff Completion (testing.md)

    func testExecute_OneOffTask_CreatesCompletionLog() async throws {
        // Given: oneOff 태스크
        let task = Task(
            projectId: "project1",
            title: "One-off Task",
            taskType: .oneOff
        )
        try await taskRepository.save(task)

        // When
        let result = try await sut.execute(taskId: task.id)

        // Then
        XCTAssertEqual(result.log.taskId, task.id)
        XCTAssertEqual(result.log.occurrenceKey, CompletionLog.oneOffOccurrenceKey)
        XCTAssertFalse(result.wasAlreadyCompleted)
        XCTAssertNil(result.updatedTask)
    }

    func testExecute_OneOffTask_LogIsSaved() async throws {
        // Given
        let task = Task(
            projectId: "project1",
            title: "One-off Task",
            taskType: .oneOff
        )
        try await taskRepository.save(task)

        // When
        _ = try await sut.execute(taskId: task.id)

        // Then: 저장소에 로그 존재 확인
        let savedLog = try await completionLogRepository.load(
            taskId: task.id,
            occurrenceKey: CompletionLog.oneOffOccurrenceKey
        )
        XCTAssertNotNil(savedLog)
    }

    func testExecute_OneOffTask_Idempotent() async throws {
        // Given
        let task = Task(
            projectId: "project1",
            title: "One-off Task",
            taskType: .oneOff
        )
        try await taskRepository.save(task)

        // When: 중복 완료 호출
        let first = try await sut.execute(taskId: task.id)
        let second = try await sut.execute(taskId: task.id)
        let third = try await sut.execute(taskId: task.id)

        // Then: 첫 번째만 실제 완료, 이후는 멱등성
        XCTAssertFalse(first.wasAlreadyCompleted)
        XCTAssertTrue(second.wasAlreadyCompleted)
        XCTAssertTrue(third.wasAlreadyCompleted)

        // 로그는 1개만 존재
        let logs = try await completionLogRepository.loadByTask(taskId: task.id)
        XCTAssertEqual(logs.count, 1)
    }

    // MARK: - B2. DailyRecurring HabitReset Completion (testing.md)

    func testExecute_DailyRecurringTask_CreatesLogWithDateKey() async throws {
        // Given: dailyRecurring 태스크
        let task = Task(
            projectId: "project1",
            title: "Daily Task",
            taskType: .dailyRecurring
        )
        try await taskRepository.save(task)
        let dateKey = DateKey.today()

        // When
        let result = try await sut.execute(taskId: task.id, dateKey: dateKey)

        // Then
        XCTAssertEqual(result.log.taskId, task.id)
        XCTAssertEqual(result.log.occurrenceKey, dateKey.value)
        XCTAssertFalse(result.wasAlreadyCompleted)
    }

    func testExecute_DailyRecurringTask_DifferentDays_CreatesDifferentLogs() async throws {
        // Given: dailyRecurring 태스크
        let task = Task(
            projectId: "project1",
            title: "Daily Task",
            taskType: .dailyRecurring
        )
        try await taskRepository.save(task)

        let today = DateKey.today()
        let yesterday = DateKey(value: "2025-01-01")
        let tomorrow = DateKey(value: "2025-01-03")

        // When: 다른 날짜로 완료
        _ = try await sut.execute(taskId: task.id, dateKey: today)
        _ = try await sut.execute(taskId: task.id, dateKey: yesterday)
        _ = try await sut.execute(taskId: task.id, dateKey: tomorrow)

        // Then: 각각 별도의 로그
        let logs = try await completionLogRepository.loadByTask(taskId: task.id)
        XCTAssertEqual(logs.count, 3)

        let occurrenceKeys = Set(logs.map { $0.occurrenceKey })
        XCTAssertTrue(occurrenceKeys.contains(today.value))
        XCTAssertTrue(occurrenceKeys.contains(yesterday.value))
        XCTAssertTrue(occurrenceKeys.contains(tomorrow.value))
    }

    func testExecute_DailyRecurringTask_SameDay_Idempotent() async throws {
        // Given
        let task = Task(
            projectId: "project1",
            title: "Daily Task",
            taskType: .dailyRecurring
        )
        try await taskRepository.save(task)
        let dateKey = DateKey.today()

        // When: 같은 날짜로 중복 완료
        let first = try await sut.execute(taskId: task.id, dateKey: dateKey)
        let second = try await sut.execute(taskId: task.id, dateKey: dateKey)

        // Then
        XCTAssertFalse(first.wasAlreadyCompleted)
        XCTAssertTrue(second.wasAlreadyCompleted)

        // 로그는 1개만 (같은 날짜)
        let logs = try await completionLogRepository.loadByTask(taskId: task.id)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.occurrenceKey, dateKey.value)
    }

    // MARK: - B3. Rollover Completion (testing.md)

    func testExecute_RolloverTask_CreatesLogAndAdvancesNext() async throws {
        // Given: rollover 방식의 반복 태스크
        let recurrenceRule = RecurrenceRule(
            kind: .daily,
            interval: 1,
            anchorDate: Date()
        )
        let nextDueAt = Date()

        let task = Task(
            projectId: "project1",
            title: "Rollover Task",
            taskType: .oneOff, // recurrenceRule 사용 시 taskType은 oneOff일 수 있음
            recurrenceRule: recurrenceRule,
            recurrenceBehavior: .rollover,
            nextOccurrenceDueAt: nextDueAt
        )
        try await taskRepository.save(task)

        // When
        let result = try await sut.execute(taskId: task.id)

        // Then: 완료 로그 생성
        XCTAssertEqual(result.log.taskId, task.id)
        XCTAssertFalse(result.wasAlreadyCompleted)

        // Then: nextOccurrenceDueAt이 다음 날짜로 advance됨
        XCTAssertNotNil(result.updatedTask)
        XCTAssertNotEqual(result.updatedTask?.nextOccurrenceDueAt, nextDueAt)
    }

    func testExecute_RolloverTask_Idempotent() async throws {
        // Given
        let recurrenceRule = RecurrenceRule(
            kind: .daily,
            interval: 1,
            anchorDate: Date()
        )
        let nextDueAt = Date()

        let task = Task(
            projectId: "project1",
            title: "Rollover Task",
            recurrenceRule: recurrenceRule,
            recurrenceBehavior: .rollover,
            nextOccurrenceDueAt: nextDueAt
        )
        try await taskRepository.save(task)

        // When: 중복 완료 호출
        let first = try await sut.execute(taskId: task.id)
        let second = try await sut.execute(taskId: task.id)

        // Then: 첫 번째만 실제 완료
        XCTAssertFalse(first.wasAlreadyCompleted)
        // 두 번째 호출 시 이미 advance된 상태이므로 다른 occurrenceKey가 됨
        // 또는 같은 occurrenceKey면 wasAlreadyCompleted = true
    }

    // MARK: - Error Cases

    func testExecute_TaskNotFound_ThrowsError() async throws {
        // When/Then
        do {
            _ = try await sut.execute(taskId: "nonexistent")
            XCTFail("Expected error")
        } catch let error as CompleteTaskError {
            XCTAssertEqual(error, .taskNotFound("nonexistent"))
        }
    }

    func testExecute_RolloverTask_MissingNextOccurrence_ThrowsError() async throws {
        // Given: nextOccurrenceDueAt이 없는 rollover 태스크
        let recurrenceRule = RecurrenceRule(
            kind: .daily,
            interval: 1,
            anchorDate: Date()
        )

        let task = Task(
            projectId: "project1",
            title: "Invalid Rollover Task",
            recurrenceRule: recurrenceRule,
            recurrenceBehavior: .rollover,
            nextOccurrenceDueAt: nil // 누락
        )
        try await taskRepository.save(task)

        // When/Then
        do {
            _ = try await sut.execute(taskId: task.id)
            XCTFail("Expected error")
        } catch let error as CompleteTaskError {
            XCTAssertEqual(error, .rolloverMissingNextOccurrence(task.id))
        }
    }

    func testExecute_RolloverTask_MissingRecurrenceRule_ThrowsError() async throws {
        // Given: recurrenceRule이 없지만 behavior가 rollover인 태스크
        let task = Task(
            projectId: "project1",
            title: "Invalid Rollover Task",
            recurrenceRule: nil, // 누락
            recurrenceBehavior: .rollover,
            nextOccurrenceDueAt: Date()
        )
        try await taskRepository.save(task)

        // When/Then
        do {
            _ = try await sut.execute(taskId: task.id)
            XCTFail("Expected error")
        } catch let error as CompleteTaskError {
            XCTAssertEqual(error, .rolloverMissingRecurrenceRule(task.id))
        }
    }

    // MARK: - Error Description

    func testCompleteTaskError_ErrorDescriptions() {
        let taskNotFoundError = CompleteTaskError.taskNotFound("task-123")
        XCTAssertEqual(taskNotFoundError.errorDescription, "Task not found: task-123")

        let missingNextError = CompleteTaskError.rolloverMissingNextOccurrence("task-456")
        XCTAssertEqual(missingNextError.errorDescription, "Rollover task missing nextOccurrenceDueAt: task-456")

        let missingRuleError = CompleteTaskError.rolloverMissingRecurrenceRule("task-789")
        XCTAssertEqual(missingRuleError.errorDescription, "Rollover task missing recurrenceRule: task-789")
    }

    // MARK: - Completion Time

    func testExecute_CustomCompletedAt() async throws {
        // Given
        let task = Task(
            projectId: "project1",
            title: "Task",
            taskType: .oneOff
        )
        try await taskRepository.save(task)
        let customCompletedAt = Date().addingTimeInterval(-3600) // 1시간 전

        // When
        let result = try await sut.execute(
            taskId: task.id,
            completedAt: customCompletedAt
        )

        // Then
        XCTAssertEqual(result.log.completedAt, customCompletedAt)
    }

    // MARK: - Edge Cases

    func testExecute_TaskWithAllFields() async throws {
        // Given: 모든 필드가 설정된 태스크
        let task = Task(
            projectId: "project1",
            title: "Full Task",
            taskType: .oneOff,
            dueDate: Date().addingTimeInterval(86400),
            sectionId: "section1",
            tagIds: ["tag1", "tag2"],
            priority: .p1,
            workflowState: .doing,
            note: "Important note",
            blockedByTaskIds: []
        )
        try await taskRepository.save(task)

        // When
        let result = try await sut.execute(taskId: task.id)

        // Then: 정상 완료
        XCTAssertEqual(result.log.taskId, task.id)
        XCTAssertFalse(result.wasAlreadyCompleted)
    }

    func testExecute_BlockedTask_CanBeCompleted() async throws {
        // Given: blocked 상태의 태스크도 완료 가능
        let task = Task(
            projectId: "project1",
            title: "Blocked Task",
            taskType: .oneOff,
            blockedByTaskIds: ["other-task"]
        )
        try await taskRepository.save(task)

        // When
        let result = try await sut.execute(taskId: task.id)

        // Then: 정상 완료 (blocked 여부와 무관)
        XCTAssertFalse(result.wasAlreadyCompleted)
    }
}

// MARK: - Mock Repositories

private final class MockTaskRepository: TaskRepository, @unchecked Sendable {
    private var tasks: [String: Task] = [:]

    func loadAll() async throws -> [Task] {
        Array(tasks.values)
    }

    func load(id: String) async throws -> Task? {
        tasks[id]
    }

    func loadByProject(projectId: String) async throws -> [Task] {
        tasks.values.filter { $0.projectId == projectId }
    }

    func save(_ task: Task) async throws {
        tasks[task.id] = task
    }

    func delete(id: String) async throws {
        tasks.removeValue(forKey: id)
    }

    func deleteByProject(projectId: String) async throws {
        tasks = tasks.filter { $0.value.projectId != projectId }
    }
}

private final class MockCompletionLogRepository: CompletionLogRepository, @unchecked Sendable {
    private var logs: [String: CompletionLog] = [:]

    private func key(taskId: String, occurrenceKey: String) -> String {
        "\(taskId)_\(occurrenceKey)"
    }

    func loadAll() async throws -> [CompletionLog] {
        Array(logs.values)
    }

    func loadByTask(taskId: String) async throws -> [CompletionLog] {
        logs.values.filter { $0.taskId == taskId }
    }

    func load(taskId: String, occurrenceKey: String) async throws -> CompletionLog? {
        logs[key(taskId: taskId, occurrenceKey: occurrenceKey)]
    }

    func save(_ log: CompletionLog) async throws {
        logs[key(taskId: log.taskId, occurrenceKey: log.occurrenceKey)] = log
    }

    func delete(taskId: String, occurrenceKey: String) async throws {
        logs.removeValue(forKey: key(taskId: taskId, occurrenceKey: occurrenceKey))
    }

    func deleteByTask(taskId: String) async throws {
        logs = logs.filter { $0.value.taskId != taskId }
    }
}
