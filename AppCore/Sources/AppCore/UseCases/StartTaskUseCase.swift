import Foundation

/// 태스크 시작 Use Case
/// - intents.md 준수: displayList[0]를 workflowState=doing으로 설정
/// - data-model.md A4: workflowState: todo/doing/done
/// - 멱등성: 이미 doing이면 noop
public struct StartTaskUseCase: Sendable {
    private let taskRepository: any TaskRepository

    public init(taskRepository: any TaskRepository) {
        self.taskRepository = taskRepository
    }

    /// 태스크 시작 (workflowState를 doing으로 전환)
    /// - Parameter taskId: 시작할 태스크 ID
    /// - Returns: 시작된 태스크
    /// - Throws: StartTaskError
    public func execute(taskId: String) async throws -> Task {
        // 1. 태스크 조회
        guard var task = try await taskRepository.load(id: taskId) else {
            throw StartTaskError.taskNotFound(taskId)
        }

        // 2. 이미 doing이면 noop (멱등성)
        if task.workflowState == .doing {
            return task
        }

        // 3. 완료된 태스크는 시작 불가
        if task.workflowState == .done {
            throw StartTaskError.alreadyCompleted(taskId)
        }

        // 4. workflowState를 doing으로 전환
        task.workflowState = .doing
        task.updatedAt = Date()

        // 5. 저장
        try await taskRepository.save(task)

        return task
    }
}

// MARK: - Errors

public enum StartTaskError: Error, LocalizedError, Equatable {
    case taskNotFound(String)
    case alreadyCompleted(String)

    public var errorDescription: String? {
        switch self {
        case .taskNotFound(let id):
            return "Task not found: \(id)"
        case .alreadyCompleted(let id):
            return "Task already completed: \(id)"
        }
    }
}
