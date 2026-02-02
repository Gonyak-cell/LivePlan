import Foundation

/// Live Activity 상태
/// - lockscreen.md A 준수: 요약 + Top 1
public struct ActivityState: Codable, Sendable, Equatable {
    /// 표시 모드
    public let displayMode: ActivityDisplayMode

    /// Top 1 태스크 (프라이버시 적용됨)
    public let topTask: ActivityTask?

    /// 카운터
    public let counters: ActivityCounters

    /// 마지막 갱신 시간
    public let lastUpdated: Date

    public init(
        displayMode: ActivityDisplayMode = .todaySummary,
        topTask: ActivityTask? = nil,
        counters: ActivityCounters = .zero,
        lastUpdated: Date = Date()
    ) {
        self.displayMode = displayMode
        self.topTask = topTask
        self.counters = counters
        self.lastUpdated = lastUpdated
    }
}

// MARK: - ActivityDisplayMode

/// Live Activity 표시 모드
public enum ActivityDisplayMode: String, Codable, Sendable {
    /// 핀 프로젝트 요약
    case pinnedSummary

    /// 오늘 요약
    case todaySummary

    /// 집중 모드 (Top 1만)
    case focusOne
}

// MARK: - ActivityTask

/// Live Activity용 태스크 (경량)
public struct ActivityTask: Codable, Sendable, Equatable {
    public let id: String
    public let displayTitle: String
    public let isOverdue: Bool
    public let isRecurring: Bool

    public init(
        id: String,
        displayTitle: String,
        isOverdue: Bool = false,
        isRecurring: Bool = false
    ) {
        self.id = id
        self.displayTitle = displayTitle
        self.isOverdue = isOverdue
        self.isRecurring = isRecurring
    }
}

// MARK: - ActivityCounters

/// Live Activity용 카운터 (경량)
public struct ActivityCounters: Codable, Sendable, Equatable {
    public let outstanding: Int
    public let overdue: Int
    public let recurringDone: Int
    public let recurringTotal: Int

    public init(
        outstanding: Int = 0,
        overdue: Int = 0,
        recurringDone: Int = 0,
        recurringTotal: Int = 0
    ) {
        self.outstanding = outstanding
        self.overdue = overdue
        self.recurringDone = recurringDone
        self.recurringTotal = recurringTotal
    }

    public static let zero = ActivityCounters()
}

// MARK: - Conversion

extension ActivityState {
    /// LockScreenSummary에서 변환
    public static func from(
        summary: LockScreenSummary,
        displayMode: ActivityDisplayMode,
        privacyMode: PrivacyMode
    ) -> ActivityState {
        let topTask: ActivityTask?
        if let first = summary.displayList.first {
            topTask = ActivityTask(
                id: first.id,
                displayTitle: first.displayTitle,
                isOverdue: first.isOverdue,
                isRecurring: first.isRecurring
            )
        } else {
            topTask = nil
        }

        return ActivityState(
            displayMode: displayMode,
            topTask: topTask,
            counters: ActivityCounters(
                outstanding: summary.counters.outstandingTotal,
                overdue: summary.counters.overdueCount,
                recurringDone: summary.counters.recurringDone,
                recurringTotal: summary.counters.recurringTotal
            )
        )
    }
}
