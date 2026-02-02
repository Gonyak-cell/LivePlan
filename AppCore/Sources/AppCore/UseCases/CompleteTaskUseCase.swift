import Foundation

/// 태스크 완료 처리 Use Case
/// - data-model.md B1/B2/B3 불변식 준수
public struct CompleteTaskUseCase: Sendable {
    private let taskRepository: any TaskRepository
    private let completionLogRepository: any CompletionLogRepository

    public init(
        taskRepository: any TaskRepository,
        completionLogRepository: any CompletionLogRepository
    ) {
        self.taskRepository = taskRepository
        self.completionLogRepository = completionLogRepository
    }

    /// 태스크 완료 처리 결과
    public struct Result: Sendable {
        /// 생성된 완료 로그
        public let log: CompletionLog
        /// 업데이트된 태스크 (rollover의 경우 nextOccurrenceDueAt가 advance됨)
        public let updatedTask: Task?
        /// 이미 완료되어 있었는지 여부 (멱등성)
        public let wasAlreadyCompleted: Bool

        public init(log: CompletionLog, updatedTask: Task? = nil, wasAlreadyCompleted: Bool = false) {
            self.log = log
            self.updatedTask = updatedTask
            self.wasAlreadyCompleted = wasAlreadyCompleted
        }
    }

    /// 태스크 완료 처리
    /// - Parameters:
    ///   - taskId: 완료할 태스크 ID
    ///   - dateKey: 기준 날짜 (habitReset용)
    ///   - completedAt: 완료 시간
    /// - Returns: 완료 결과 (CompletionLog + 업데이트된 Task)
    public func execute(
        taskId: String,
        dateKey: DateKey = .today(),
        completedAt: Date = Date()
    ) async throws -> Result {
        // 1. 태스크 조회
        guard let task = try await taskRepository.load(id: taskId) else {
            throw CompleteTaskError.taskNotFound(taskId)
        }

        // 2. 반복 행태에 따라 분기
        if task.isRollover {
            return try await executeRollover(task: task, completedAt: completedAt)
        } else {
            return try await executeHabitResetOrOneOff(task: task, dateKey: dateKey, completedAt: completedAt)
        }
    }

    // MARK: - Rollover Completion (data-model.md B3)

    /// Rollover 반복 태스크 완료 처리
    /// - occurrenceKey = dateKey(nextOccurrenceDueAt)
    /// - 완료 시 nextOccurrenceDueAt을 다음 occurrence로 advance
    private func executeRollover(
        task: Task,
        completedAt: Date
    ) async throws -> Result {
        // nextOccurrenceDueAt이 없으면 오류
        guard let currentDueAt = task.nextOccurrenceDueAt else {
            throw CompleteTaskError.rolloverMissingNextOccurrence(task.id)
        }

        // occurrenceKey = dateKey(nextOccurrenceDueAt)
        let log = CompletionLog.forRollover(
            taskId: task.id,
            occurrenceDueAt: currentDueAt,
            completedAt: completedAt
        )

        // 중복 검사 (멱등성)
        let existing = try await completionLogRepository.load(
            taskId: log.taskId,
            occurrenceKey: log.occurrenceKey
        )

        if existing != nil {
            // 이미 완료됨 - 멱등성 유지
            return Result(log: log, updatedTask: nil, wasAlreadyCompleted: true)
        }

        // 다음 occurrence 계산
        guard let recurrenceRule = task.recurrenceRule else {
            throw CompleteTaskError.rolloverMissingRecurrenceRule(task.id)
        }

        let nextDueAt = recurrenceRule.nextOccurrence(after: currentDueAt)

        // Task 업데이트 (nextOccurrenceDueAt advance)
        var updatedTask = task
        updatedTask.nextOccurrenceDueAt = nextDueAt
        updatedTask.updatedAt = completedAt

        // 저장 (CompletionLog + Task)
        try await completionLogRepository.save(log)
        try await taskRepository.save(updatedTask)

        return Result(log: log, updatedTask: updatedTask, wasAlreadyCompleted: false)
    }

    // MARK: - HabitReset / OneOff Completion (data-model.md B1/B2)

    /// HabitReset 또는 OneOff 태스크 완료 처리
    private func executeHabitResetOrOneOff(
        task: Task,
        dateKey: DateKey,
        completedAt: Date
    ) async throws -> Result {
        let log: CompletionLog

        switch task.taskType {
        case .oneOff:
            // oneOff: occurrenceKey = "once"
            log = CompletionLog.forOneOff(taskId: task.id, completedAt: completedAt)

        case .dailyRecurring:
            // dailyRecurring (habitReset): occurrenceKey = dateKey
            log = CompletionLog.forDailyRecurring(
                taskId: task.id,
                dateKey: dateKey.value,
                completedAt: completedAt
            )
        }

        // 중복 검사 (멱등성)
        let existing = try await completionLogRepository.load(
            taskId: log.taskId,
            occurrenceKey: log.occurrenceKey
        )

        if existing != nil {
            // 이미 완료됨 - 멱등성 유지
            return Result(log: log, updatedTask: nil, wasAlreadyCompleted: true)
        }

        // 저장
        try await completionLogRepository.save(log)

        return Result(log: log, updatedTask: nil, wasAlreadyCompleted: false)
    }

    // MARK: - Legacy API (하위 호환)

    /// 레거시 API: CompletionLog만 반환
    @available(*, deprecated, message: "Use execute() returning Result instead")
    public func executeReturningLog(
        taskId: String,
        dateKey: DateKey = .today(),
        completedAt: Date = Date()
    ) async throws -> CompletionLog {
        let result = try await execute(taskId: taskId, dateKey: dateKey, completedAt: completedAt)
        return result.log
    }
}

// MARK: - Errors

public enum CompleteTaskError: Error, LocalizedError {
    /// 태스크를 찾을 수 없음
    case taskNotFound(String)
    /// rollover 태스크인데 nextOccurrenceDueAt이 없음
    case rolloverMissingNextOccurrence(String)
    /// rollover 태스크인데 recurrenceRule이 없음
    case rolloverMissingRecurrenceRule(String)

    public var errorDescription: String? {
        switch self {
        case .taskNotFound(let id):
            return "Task not found: \(id)"
        case .rolloverMissingNextOccurrence(let id):
            return "Rollover task missing nextOccurrenceDueAt: \(id)"
        case .rolloverMissingRecurrenceRule(let id):
            return "Rollover task missing recurrenceRule: \(id)"
        }
    }
}
