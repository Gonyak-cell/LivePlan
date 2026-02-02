import Foundation

/// 필터 정의
/// - data-model.md A7 준수
/// - 조건 조합(AND)으로 태스크 필터링
/// - Todoist 필터 개념을 벤치마크
public struct FilterDefinition: Codable, Equatable, Sendable {
    // MARK: - Scope Filters

    /// 포함할 프로젝트 ID 목록 (nil이면 모든 프로젝트)
    public var includeProjectIds: [String]?

    /// 포함할 섹션 ID 목록 (nil이면 모든 섹션)
    public var includeSectionIds: [String]?

    /// 포함할 태그 ID 목록 (nil이면 태그 무관)
    public var includeTagIds: [String]?

    // MARK: - Priority Filters

    /// 최소 우선순위 (이 우선순위 이상, P1이 가장 높음)
    /// 예: priorityAtLeast = .p2 → P1, P2 포함
    public var priorityAtLeast: Priority?

    /// 최대 우선순위 (이 우선순위 이하)
    /// 예: priorityAtMost = .p2 → P2, P3, P4 포함
    public var priorityAtMost: Priority?

    // MARK: - State Filters

    /// 포함할 상태 목록 (nil이면 done 제외가 기본)
    /// 예: [.todo, .doing] → todo, doing만 포함
    public var stateIn: Set<WorkflowState>?

    // MARK: - Due Date Filters

    /// 마감일 범위
    public var dueRange: DueRange?

    // MARK: - Recurrence/Block Filters

    /// 반복 태스크 포함 여부 (nil이면 모두 포함)
    public var includeRecurring: Bool?

    /// 차단된 태스크 제외 여부 (기본 true)
    public var excludeBlocked: Bool

    // MARK: - Initializer

    public init(
        includeProjectIds: [String]? = nil,
        includeSectionIds: [String]? = nil,
        includeTagIds: [String]? = nil,
        priorityAtLeast: Priority? = nil,
        priorityAtMost: Priority? = nil,
        stateIn: Set<WorkflowState>? = nil,
        dueRange: DueRange? = nil,
        includeRecurring: Bool? = nil,
        excludeBlocked: Bool = true
    ) {
        self.includeProjectIds = includeProjectIds
        self.includeSectionIds = includeSectionIds
        self.includeTagIds = includeTagIds
        self.priorityAtLeast = priorityAtLeast
        self.priorityAtMost = priorityAtMost
        self.stateIn = stateIn
        self.dueRange = dueRange
        self.includeRecurring = includeRecurring
        self.excludeBlocked = excludeBlocked
    }
}

// MARK: - DueRange

/// 마감일 범위 필터
public enum DueRange: String, Codable, CaseIterable, Sendable {
    /// 오늘 마감
    case today

    /// 향후 7일 이내 마감
    case next7

    /// 지연됨 (마감일이 과거)
    case overdue

    /// 마감일 없음
    case none

    /// 마감일 있음 (범위 무관)
    case any
}

// MARK: - Empty Filter

extension FilterDefinition {
    /// 빈 필터 (모든 태스크 포함, blocked만 제외)
    public static let empty = FilterDefinition()

    /// 모든 태스크 포함 (blocked도 포함)
    public static let all = FilterDefinition(excludeBlocked: false)

    /// 빈 필터인지 여부
    public var isEmpty: Bool {
        includeProjectIds == nil &&
        includeSectionIds == nil &&
        includeTagIds == nil &&
        priorityAtLeast == nil &&
        priorityAtMost == nil &&
        stateIn == nil &&
        dueRange == nil &&
        includeRecurring == nil &&
        excludeBlocked == true
    }
}

// MARK: - Convenience Builders

extension FilterDefinition {
    /// 특정 프로젝트만 필터
    public static func project(_ projectId: String) -> FilterDefinition {
        FilterDefinition(includeProjectIds: [projectId])
    }

    /// 특정 태그만 필터
    public static func tag(_ tagId: String) -> FilterDefinition {
        FilterDefinition(includeTagIds: [tagId])
    }

    /// 우선순위 필터 (지정된 우선순위 이상)
    public static func priorityAtLeast(_ priority: Priority) -> FilterDefinition {
        FilterDefinition(priorityAtLeast: priority)
    }

    /// 마감일 범위 필터
    public static func due(_ range: DueRange) -> FilterDefinition {
        FilterDefinition(dueRange: range)
    }
}

// MARK: - Filter Combination

extension FilterDefinition {
    /// 다른 필터와 AND 조합
    /// - 두 필터의 조건을 모두 충족해야 함
    public func combined(with other: FilterDefinition) -> FilterDefinition {
        FilterDefinition(
            includeProjectIds: combineArrays(includeProjectIds, other.includeProjectIds),
            includeSectionIds: combineArrays(includeSectionIds, other.includeSectionIds),
            includeTagIds: combineArrays(includeTagIds, other.includeTagIds),
            priorityAtLeast: higherPriority(priorityAtLeast, other.priorityAtLeast),
            priorityAtMost: lowerPriority(priorityAtMost, other.priorityAtMost),
            stateIn: combineSets(stateIn, other.stateIn),
            dueRange: dueRange ?? other.dueRange,
            includeRecurring: includeRecurring ?? other.includeRecurring,
            excludeBlocked: excludeBlocked || other.excludeBlocked
        )
    }

    private func combineArrays(_ a: [String]?, _ b: [String]?) -> [String]? {
        guard let a = a else { return b }
        guard let b = b else { return a }
        // 교집합
        return Array(Set(a).intersection(Set(b)))
    }

    private func combineSets(_ a: Set<WorkflowState>?, _ b: Set<WorkflowState>?) -> Set<WorkflowState>? {
        guard let a = a else { return b }
        guard let b = b else { return a }
        return a.intersection(b)
    }

    private func higherPriority(_ a: Priority?, _ b: Priority?) -> Priority? {
        guard let a = a else { return b }
        guard let b = b else { return a }
        // 더 높은(숫자가 작은) 우선순위 선택
        return a < b ? a : b
    }

    private func lowerPriority(_ a: Priority?, _ b: Priority?) -> Priority? {
        guard let a = a else { return b }
        guard let b = b else { return a }
        // 더 낮은(숫자가 큰) 우선순위 선택
        return a > b ? a : b
    }
}

// MARK: - Description

extension FilterDefinition {
    /// 사용자 표시용 요약 (KR)
    public var summaryKR: String {
        var parts: [String] = []

        if let ids = includeProjectIds, !ids.isEmpty {
            parts.append("프로젝트 \(ids.count)개")
        }
        if let ids = includeTagIds, !ids.isEmpty {
            parts.append("태그 \(ids.count)개")
        }
        if let priority = priorityAtLeast {
            parts.append("\(priority.label) 이상")
        }
        if let states = stateIn {
            parts.append(states.map { $0.descriptionKR }.joined(separator: "/"))
        }
        if let range = dueRange {
            parts.append(range.descriptionKR)
        }
        if excludeBlocked {
            parts.append("차단 제외")
        }

        return parts.isEmpty ? "전체" : parts.joined(separator: ", ")
    }
}

extension DueRange {
    /// 사용자 표시용 설명 (KR)
    public var descriptionKR: String {
        switch self {
        case .today: return "오늘"
        case .next7: return "7일 이내"
        case .overdue: return "지연"
        case .none: return "마감일 없음"
        case .any: return "마감일 있음"
        }
    }

    /// 사용자 표시용 설명 (EN)
    public var descriptionEN: String {
        switch self {
        case .today: return "Today"
        case .next7: return "Next 7 days"
        case .overdue: return "Overdue"
        case .none: return "No due date"
        case .any: return "Has due date"
        }
    }
}
