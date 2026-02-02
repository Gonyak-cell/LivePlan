import XCTest
@testable import AppCore

/// StartTaskUseCase 테스트
/// - intents.md: StartNextTask workflowState=doing 전환
/// - 멱등성: 이미 doing이면 noop
final class StartTaskUseCaseTests: XCTestCase {

    private var taskRepository: MockTaskRepository!
    private var sut: StartTaskUseCase!

    override func setUp() {
        super.setUp()
        taskRepository = MockTaskRepository()
        sut = StartTaskUseCase(taskRepository: taskRepository)
    }

    override func tearDown() {
        taskRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Success Cases

    func testExecute_TodoTask_BecomesDoingState() async throws {
        // Given: todo 상태의 태스크
        let task = Task(
            projectId: "project1",
            title: "Test Task",
            workflowState: .todo
        )
        try await taskRepository.save(task)

        // When
        let started = try await sut.execute(taskId: task.id)

        // Then
        XCTAssertEqual(started.workflowState, .doing)
        XCTAssertGreaterThan(started.updatedAt, task.updatedAt)

        // Repository에도 반영 확인
        let saved = try await taskRepository.load(id: task.id)
        XCTAssertEqual(saved?.workflowState, .doing)
    }

    // MARK: - Idempotency

    func testExecute_AlreadyDoing_ReturnsWithoutChange() async throws {
        // Given: 이미 doing 상태의 태스크
        let task = Task(
            projectId: "project1",
            title: "Test Task",
            workflowState: .doing
        )
        try await taskRepository.save(task)

        // When: 다시 시작 호출 (멱등성)
        let result = try await sut.execute(taskId: task.id)

        // Then: 상태 유지, 에러 없음
        XCTAssertEqual(result.workflowState, .doing)
        XCTAssertEqual(result.id, task.id)
    }

    func testExecute_MultipleStartCalls_Idempotent() async throws {
        // Given
        let task = Task(
            projectId: "project1",
            title: "Test Task",
            workflowState: .todo
        )
        try await taskRepository.save(task)

        // When: 여러 번 호출
        let first = try await sut.execute(taskId: task.id)
        let second = try await sut.execute(taskId: task.id)
        let third = try await sut.execute(taskId: task.id)

        // Then: 모두 doing 상태, 에러 없음
        XCTAssertEqual(first.workflowState, .doing)
        XCTAssertEqual(second.workflowState, .doing)
        XCTAssertEqual(third.workflowState, .doing)
    }

    // MARK: - Error Cases

    func testExecute_TaskNotFound_ThrowsError() async throws {
        // Given: 존재하지 않는 태스크 ID

        // When/Then
        do {
            _ = try await sut.execute(taskId: "nonexistent")
            XCTFail("Expected error")
        } catch let error as StartTaskError {
            XCTAssertEqual(error, .taskNotFound("nonexistent"))
        }
    }

    func testExecute_AlreadyCompleted_ThrowsError() async throws {
        // Given: 이미 완료된 태스크
        let task = Task(
            projectId: "project1",
            title: "Completed Task",
            workflowState: .done
        )
        try await taskRepository.save(task)

        // When/Then
        do {
            _ = try await sut.execute(taskId: task.id)
            XCTFail("Expected error")
        } catch let error as StartTaskError {
            XCTAssertEqual(error, .alreadyCompleted(task.id))
        }
    }

    // MARK: - Edge Cases

    func testExecute_BlockedTask_CanBeStarted() async throws {
        // Given: blocked 상태의 태스크 (직접 시작은 허용)
        let task = Task(
            projectId: "project1",
            title: "Blocked Task",
            workflowState: .todo,
            blockedByTaskIds: ["other-task"]
        )
        try await taskRepository.save(task)

        // When
        let started = try await sut.execute(taskId: task.id)

        // Then: blocked 여부와 상관없이 시작 가능
        XCTAssertEqual(started.workflowState, .doing)
        XCTAssertTrue(started.isBlocked)
    }

    func testExecute_RecurringTask_CanBeStarted() async throws {
        // Given: 반복 태스크
        let task = Task(
            projectId: "project1",
            title: "Daily Task",
            taskType: .dailyRecurring,
            workflowState: .todo
        )
        try await taskRepository.save(task)

        // When
        let started = try await sut.execute(taskId: task.id)

        // Then
        XCTAssertEqual(started.workflowState, .doing)
        XCTAssertTrue(started.isRecurring)
    }

    func testExecute_HighPriorityTask_CanBeStarted() async throws {
        // Given: P1 우선순위 태스크
        let task = Task(
            projectId: "project1",
            title: "Urgent Task",
            priority: .p1,
            workflowState: .todo
        )
        try await taskRepository.save(task)

        // When
        let started = try await sut.execute(taskId: task.id)

        // Then
        XCTAssertEqual(started.workflowState, .doing)
        XCTAssertEqual(started.priority, .p1)
    }

    // MARK: - Error Description

    func testStartTaskError_ErrorDescriptions() {
        let taskNotFoundError = StartTaskError.taskNotFound("task-123")
        XCTAssertEqual(taskNotFoundError.errorDescription, "Task not found: task-123")

        let alreadyCompletedError = StartTaskError.alreadyCompleted("task-456")
        XCTAssertEqual(alreadyCompletedError.errorDescription, "Task already completed: task-456")
    }
}

// MARK: - Mock Repository

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
