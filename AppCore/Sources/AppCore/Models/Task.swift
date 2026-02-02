import Foundation

/// 태스크 엔티티
/// - data-model.md A4 준수
/// - Phase 2: priority/workflowState/tags/sections/recurrence 확장
public struct Task: Identifiable, Codable, Equatable, Sendable {
    // MARK: - Required Fields

    public let id: String
    public var projectId: String
    public var title: String

    // MARK: - Basic Attributes (Phase 1)

    public var taskType: TaskType
    public var dueDate: Date?
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Phase 2 Extensions

    /// 섹션 ID (없으면 미분류)
    public var sectionId: String?

    /// 태그 ID 목록 (다대다)
    public var tagIds: [String]

    /// 우선순위 (기본 P4)
    public var priority: Priority

    /// 워크플로 상태 (기본 todo)
    public var workflowState: WorkflowState

    /// 시작 시간 (캘린더/타임라인용, 선택)
    public var startAt: Date?

    /// 노트 (Notion-lite)
    public var note: String?

    /// 선행 태스크 ID 목록 (Dependencies-lite, 동일 프로젝트 내)
    public var blockedByTaskIds: [String]

    // MARK: - Recurrence (Phase 2)

    /// 반복 규칙 (없으면 비반복, RecurrenceRule 사용 시)
    public var recurrenceRule: RecurrenceRule?

    /// 반복 행태 (habitReset / rollover)
    public var recurrenceBehavior: RecurrenceBehavior?

    /// 다음 occurrence 마감일 (rollover용)
    public var nextOccurrenceDueAt: Date?

    // MARK: - Initializer

    public init(
        id: String = UUID().uuidString,
        projectId: String,
        title: String,
        taskType: TaskType = .oneOff,
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        // Phase 2 fields
        sectionId: String? = nil,
        tagIds: [String] = [],
        priority: Priority = .defaultPriority,
        workflowState: WorkflowState = .defaultState,
        startAt: Date? = nil,
        note: String? = nil,
        blockedByTaskIds: [String] = [],
        recurrenceRule: RecurrenceRule? = nil,
        recurrenceBehavior: RecurrenceBehavior? = nil,
        nextOccurrenceDueAt: Date? = nil
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.taskType = taskType
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sectionId = sectionId
        self.tagIds = tagIds
        self.priority = priority
        self.workflowState = workflowState
        self.startAt = startAt
        self.note = note
        self.blockedByTaskIds = blockedByTaskIds
        self.recurrenceRule = recurrenceRule
        self.recurrenceBehavior = recurrenceBehavior
        self.nextOccurrenceDueAt = nextOccurrenceDueAt
    }
}

// MARK: - TaskType

/// 태스크 유형 (Phase 1 호환)
/// - oneOff: 일반 태스크 (1회성)
/// - dailyRecurring: 매일 반복 태스크 (habitReset 기본)
public enum TaskType: String, Codable, CaseIterable, Sendable {
    case oneOff
    case dailyRecurring
}

// MARK: - Recurrence Convenience

extension Task {
    /// 반복 태스크 여부 (TaskType 또는 RecurrenceRule 기반)
    public var isRecurring: Bool {
        taskType == .dailyRecurring || recurrenceRule != nil
    }

    /// 일회성 태스크 여부
    public var isOneOff: Bool {
        !isRecurring
    }

    /// 실제 적용되는 반복 행태
    /// - dailyRecurring: habitReset (기본)
    /// - recurrenceRule 사용: rollover (기본) 또는 명시된 값
    public var effectiveRecurrenceBehavior: RecurrenceBehavior? {
        if let behavior = recurrenceBehavior {
            return behavior
        }
        if taskType == .dailyRecurring {
            return .defaultForDailyRecurring
        }
        if recurrenceRule != nil {
            return .defaultForRecurrenceRule
        }
        return nil
    }

    /// habitReset 방식인지 여부
    public var isHabitReset: Bool {
        effectiveRecurrenceBehavior == .habitReset
    }

    /// rollover 방식인지 여부
    public var isRollover: Bool {
        effectiveRecurrenceBehavior == .rollover
    }
}

// MARK: - Due Date Convenience

extension Task {
    /// 마감일 존재 여부
    public var hasDueDate: Bool {
        dueDate != nil
    }

    /// 실제 적용되는 마감일 (rollover의 경우 nextOccurrenceDueAt 우선)
    public var effectiveDueDate: Date? {
        if isRollover, let next = nextOccurrenceDueAt {
            return next
        }
        return dueDate
    }
}

// MARK: - Dependencies

extension Task {
    /// 다른 태스크에 의해 차단되어 있는지 여부
    public var isBlocked: Bool {
        !blockedByTaskIds.isEmpty
    }

    /// 특정 태스크에 의해 차단되어 있는지 확인
    public func isBlockedBy(_ taskId: String) -> Bool {
        blockedByTaskIds.contains(taskId)
    }
}

// MARK: - Workflow Convenience

extension Task {
    /// 완료 상태인지 여부 (workflowState 기반)
    public var isDone: Bool {
        workflowState == .done
    }

    /// 진행 중인지 여부
    public var isInProgress: Bool {
        workflowState == .doing
    }

    /// 활성 상태인지 여부 (todo 또는 doing)
    public var isActive: Bool {
        workflowState.isActive
    }
}

// MARK: - Tags Convenience

extension Task {
    /// 태그가 있는지 여부
    public var hasTags: Bool {
        !tagIds.isEmpty
    }

    /// 특정 태그가 있는지 확인
    public func hasTag(_ tagId: String) -> Bool {
        tagIds.contains(tagId)
    }
}

// MARK: - Validation

extension Task {
    /// 유효성 검사 오류
    public enum ValidationError: Error, Equatable {
        /// blockedByTaskIds에 자기 자신 포함
        case selfReference
        /// recurrenceRule이 유효하지 않음
        case invalidRecurrenceRule(RecurrenceRule.ValidationError)
    }

    /// 유효성 검사
    public func validate() -> ValidationError? {
        // 자기 참조 금지
        if blockedByTaskIds.contains(id) {
            return .selfReference
        }

        // recurrenceRule 유효성
        if let rule = recurrenceRule, let error = rule.validate() {
            return .invalidRecurrenceRule(error)
        }

        return nil
    }

    /// 유효한 태스크인지 여부
    public var isValid: Bool {
        validate() == nil
    }
}

// MARK: - Codable (Migration Support)

extension Task {
    /// Phase 1 데이터 마이그레이션 지원을 위한 커스텀 디코딩
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        projectId = try container.decode(String.self, forKey: .projectId)
        title = try container.decode(String.self, forKey: .title)
        taskType = try container.decode(TaskType.self, forKey: .taskType)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // Phase 2 fields with defaults for migration
        sectionId = try container.decodeIfPresent(String.self, forKey: .sectionId)
        tagIds = try container.decodeIfPresent([String].self, forKey: .tagIds) ?? []
        priority = try container.decodeIfPresent(Priority.self, forKey: .priority) ?? .defaultPriority
        workflowState = try container.decodeIfPresent(WorkflowState.self, forKey: .workflowState) ?? .defaultState
        startAt = try container.decodeIfPresent(Date.self, forKey: .startAt)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        blockedByTaskIds = try container.decodeIfPresent([String].self, forKey: .blockedByTaskIds) ?? []
        recurrenceRule = try container.decodeIfPresent(RecurrenceRule.self, forKey: .recurrenceRule)
        recurrenceBehavior = try container.decodeIfPresent(RecurrenceBehavior.self, forKey: .recurrenceBehavior)
        nextOccurrenceDueAt = try container.decodeIfPresent(Date.self, forKey: .nextOccurrenceDueAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id, projectId, title, taskType, dueDate, createdAt, updatedAt
        case sectionId, tagIds, priority, workflowState, startAt, note
        case blockedByTaskIds, recurrenceRule, recurrenceBehavior, nextOccurrenceDueAt
    }
}
