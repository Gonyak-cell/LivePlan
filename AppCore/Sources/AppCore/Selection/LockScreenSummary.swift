import Foundation

/// 잠금화면 표시용 요약 DTO
/// - lockscreen.md A 준수
public struct LockScreenSummary: Equatable, Sendable {
    /// 표시할 태스크 목록 (Top N)
    public let displayList: [DisplayTask]

    /// 카운터들
    public let counters: Counters

    /// 폴백 사유 (디버그/로깅용)
    public let fallbackReason: FallbackReason?

    public init(
        displayList: [DisplayTask],
        counters: Counters,
        fallbackReason: FallbackReason? = nil
    ) {
        self.displayList = displayList
        self.counters = counters
        self.fallbackReason = fallbackReason
    }
}

// MARK: - DisplayTask

/// 표시용 태스크 (프라이버시 적용됨)
public struct DisplayTask: Identifiable, Equatable, Sendable {
    public let id: String
    public let displayTitle: String
    public let isOverdue: Bool
    public let isDueSoon: Bool
    public let isRecurring: Bool
    /// 작업 중 여부 (G1 그룹)
    public let isDoing: Bool
    /// 우선순위 (P1~P4)
    public let priority: Priority

    public init(
        id: String,
        displayTitle: String,
        isOverdue: Bool = false,
        isDueSoon: Bool = false,
        isRecurring: Bool = false,
        isDoing: Bool = false,
        priority: Priority = .defaultPriority
    ) {
        self.id = id
        self.displayTitle = displayTitle
        self.isOverdue = isOverdue
        self.isDueSoon = isDueSoon
        self.isRecurring = isRecurring
        self.isDoing = isDoing
        self.priority = priority
    }

    /// P1 우선순위인지 여부 (편의 플래그)
    public var isP1: Bool {
        priority == .p1
    }
}

// MARK: - Counters

/// 카운터 집합
/// - lockscreen.md B 준수
/// - 필수: outstandingTotal, overdueCount, dueSoonCount, recurringDone/Total
/// - 선택: p1Count, doingCount, blockedCount
public struct Counters: Equatable, Sendable {
    /// 전체 미완료 수
    public let outstandingTotal: Int

    /// 지연(overdue) 수
    public let overdueCount: Int

    /// 임박(dueSoon) 수
    public let dueSoonCount: Int

    /// 반복 중 오늘 완료 수
    public let recurringDone: Int

    /// 전체 반복 수
    public let recurringTotal: Int

    /// P1 우선순위 태스크 수 (선택)
    public let p1Count: Int

    /// 작업 중(doing) 태스크 수 (선택)
    public let doingCount: Int

    /// 차단된(blocked) 태스크 수 (선택)
    public let blockedCount: Int

    public init(
        outstandingTotal: Int = 0,
        overdueCount: Int = 0,
        dueSoonCount: Int = 0,
        recurringDone: Int = 0,
        recurringTotal: Int = 0,
        p1Count: Int = 0,
        doingCount: Int = 0,
        blockedCount: Int = 0
    ) {
        self.outstandingTotal = outstandingTotal
        self.overdueCount = overdueCount
        self.dueSoonCount = dueSoonCount
        self.recurringDone = recurringDone
        self.recurringTotal = recurringTotal
        self.p1Count = p1Count
        self.doingCount = doingCount
        self.blockedCount = blockedCount
    }

    /// 빈 카운터
    public static let zero = Counters()
}

// MARK: - FallbackReason

/// 폴백 사유
public enum FallbackReason: String, Sendable {
    case noPinnedProject = "pinned_project_not_set"
    case pinnedProjectArchived = "pinned_project_archived"
    case pinnedProjectCompleted = "pinned_project_completed"
    case noTasks = "no_tasks"
    case allCompleted = "all_completed"
}

// MARK: - Empty State

extension LockScreenSummary {
    /// 빈 상태
    public static let empty = LockScreenSummary(
        displayList: [],
        counters: .zero,
        fallbackReason: .noTasks
    )
}
