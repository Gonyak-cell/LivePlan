import Foundation

/// 태스크 수정 Use Case
/// - data-model.md A4: Task 엔티티 정의 준수
/// - architecture.md B3: AppCore에서 도메인 판단
public struct UpdateTaskUseCase: Sendable {
    private let taskRepository: any TaskRepository
    private let projectRepository: any ProjectRepository

    public init(
        taskRepository: any TaskRepository,
        projectRepository: any ProjectRepository
    ) {
        self.taskRepository = taskRepository
        self.projectRepository = projectRepository
    }

    /// 태스크 수정
    /// - Parameters:
    ///   - taskId: 수정할 태스크 ID
    ///   - title: 새 제목 (nil이면 변경 안 함)
    ///   - projectId: 새 프로젝트 ID (nil이면 변경 안 함)
    ///   - taskType: 새 태스크 유형 (nil이면 변경 안 함)
    ///   - dueDate: 새 마감일 (.some(date)면 설정, .some(nil)이면 제거, nil이면 변경 안 함)
    ///   - priority: 새 우선순위 (nil이면 변경 안 함)
    ///   - workflowState: 새 워크플로 상태 (nil이면 변경 안 함)
    ///   - sectionId: 새 섹션 ID (.some(id)면 설정, .some(nil)이면 제거, nil이면 변경 안 함)
    ///   - tagIds: 새 태그 ID 목록 (nil이면 변경 안 함)
    ///   - note: 새 노트 (.some(text)면 설정, .some(nil)이면 제거, nil이면 변경 안 함)
    ///   - startAt: 새 시작 시간 (.some(date)면 설정, .some(nil)이면 제거, nil이면 변경 안 함)
    ///   - blockedByTaskIds: 새 선행 태스크 ID 목록 (nil이면 변경 안 함)
    ///   - recurrenceRule: 새 반복 규칙 (.some(rule)이면 설정, .some(nil)이면 제거, nil이면 변경 안 함)
    ///   - recurrenceBehavior: 새 반복 행태 (.some(behavior)면 설정, .some(nil)이면 제거, nil이면 변경 안 함)
    /// - Returns: 수정된 태스크
    public func execute(
        taskId: String,
        title: String? = nil,
        projectId: String? = nil,
        taskType: TaskType? = nil,
        dueDate: OptionalValue<Date>? = nil,
        priority: Priority? = nil,
        workflowState: WorkflowState? = nil,
        sectionId: OptionalValue<String>? = nil,
        tagIds: [String]? = nil,
        note: OptionalValue<String>? = nil,
        startAt: OptionalValue<Date>? = nil,
        blockedByTaskIds: [String]? = nil,
        recurrenceRule: OptionalValue<RecurrenceRule>? = nil,
        recurrenceBehavior: OptionalValue<RecurrenceBehavior>? = nil
    ) async throws -> Task {
        // 1. 기존 태스크 조회
        guard var task = try await taskRepository.load(id: taskId) else {
            throw UpdateTaskError.taskNotFound(taskId)
        }

        // 2. 제목 수정
        if let newTitle = title {
            let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else {
                throw UpdateTaskError.emptyTitle
            }
            task.title = trimmedTitle
        }

        // 3. 프로젝트 변경
        if let newProjectId = projectId {
            guard try await projectRepository.load(id: newProjectId) != nil else {
                throw UpdateTaskError.projectNotFound(newProjectId)
            }
            task.projectId = newProjectId
            // 프로젝트 변경 시 섹션 초기화 (다른 프로젝트의 섹션은 유효하지 않음)
            task.sectionId = nil
            // 프로젝트 변경 시 blockedByTaskIds도 초기화 (동일 프로젝트 내 제약)
            task.blockedByTaskIds = []
        }

        // 4. 태스크 유형 수정
        if let newTaskType = taskType {
            task.taskType = newTaskType
        }

        // 5. 마감일 수정
        if let dueDateValue = dueDate {
            task.dueDate = dueDateValue.value
        }

        // 6. 우선순위 수정
        if let newPriority = priority {
            task.priority = newPriority
        }

        // 7. 워크플로 상태 수정
        if let newState = workflowState {
            task.workflowState = newState
        }

        // 8. 섹션 수정 (프로젝트 변경과 별도로 지정된 경우만)
        if projectId == nil, let sectionValue = sectionId {
            task.sectionId = sectionValue.value
        }

        // 9. 태그 수정
        if let newTagIds = tagIds {
            task.tagIds = newTagIds
        }

        // 10. 노트 수정
        if let noteValue = note {
            task.note = noteValue.value
        }

        // 11. 시작 시간 수정
        if let startAtValue = startAt {
            task.startAt = startAtValue.value
        }

        // 12. 선행 태스크 수정
        if let newBlockedByTaskIds = blockedByTaskIds {
            // 자기 자신 참조 금지 (data-model.md A4 제약)
            if newBlockedByTaskIds.contains(taskId) {
                throw UpdateTaskError.selfReference
            }
            // 동일 프로젝트 내 태스크만 허용 (data-model.md A4 제약)
            for blockedId in newBlockedByTaskIds {
                guard let blockedTask = try await taskRepository.load(id: blockedId) else {
                    throw UpdateTaskError.blockedTaskNotFound(blockedId)
                }
                if blockedTask.projectId != task.projectId {
                    throw UpdateTaskError.crossProjectDependency(blockedId)
                }
            }
            task.blockedByTaskIds = newBlockedByTaskIds
        }

        // 13. 반복 규칙 수정
        if let ruleValue = recurrenceRule {
            if let rule = ruleValue.value, let error = rule.validate() {
                throw UpdateTaskError.invalidRecurrenceRule(error)
            }
            task.recurrenceRule = ruleValue.value
        }

        // 14. 반복 행태 수정
        if let behaviorValue = recurrenceBehavior {
            task.recurrenceBehavior = behaviorValue.value
        }

        // 15. updatedAt 갱신
        task.updatedAt = Date()

        // 16. 저장
        try await taskRepository.save(task)

        return task
    }
}

// MARK: - OptionalValue

/// Optional 필드의 "변경 안 함" vs "nil로 설정"을 구분하기 위한 wrapper
public enum OptionalValue<T: Sendable>: Sendable {
    case value(T?)

    public var value: T? {
        switch self {
        case .value(let v): return v
        }
    }

    /// nil로 설정 (필드 제거)
    public static var none: OptionalValue<T> { .value(nil) }

    /// 값 설정
    public static func some(_ value: T) -> OptionalValue<T> { .value(value) }
}

// MARK: - Errors

public enum UpdateTaskError: Error, LocalizedError, Equatable {
    case taskNotFound(String)
    case emptyTitle
    case projectNotFound(String)
    case selfReference
    case blockedTaskNotFound(String)
    case crossProjectDependency(String)
    case invalidRecurrenceRule(RecurrenceRule.ValidationError)

    public var errorDescription: String? {
        switch self {
        case .taskNotFound(let id):
            return "Task not found: \(id)"
        case .emptyTitle:
            return "Task title cannot be empty"
        case .projectNotFound(let id):
            return "Project not found: \(id)"
        case .selfReference:
            return "Task cannot block itself"
        case .blockedTaskNotFound(let id):
            return "Blocked task not found: \(id)"
        case .crossProjectDependency(let id):
            return "Cross-project dependency not allowed: \(id)"
        case .invalidRecurrenceRule(let error):
            return "Invalid recurrence rule: \(error)"
        }
    }
}
