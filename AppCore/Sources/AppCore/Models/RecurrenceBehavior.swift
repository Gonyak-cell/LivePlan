import Foundation

/// 반복 태스크의 완료 행태
/// - data-model.md A4 준수
/// - product-decisions.md 3.3 준수
public enum RecurrenceBehavior: String, Codable, CaseIterable, Sendable {
    /// 습관 리셋 (기존 dailyRecurring 동작)
    /// - 체크 안 해도 다음 날 새로 시작 (표시 리셋)
    /// - 전날 미완료가 누적되지 않음
    /// - occurrenceKey = dateKey (YYYY-MM-DD)
    case habitReset

    /// 롤오버 (프로젝트/업무 관리형)
    /// - 미완료는 지연(overdue)으로 남아있음
    /// - 완료 시 다음 occurrence로 이동
    /// - occurrenceKey = nextOccurrenceDueAt 기반 dateKey
    case rollover
}

// MARK: - Default Values

extension RecurrenceBehavior {
    /// dailyRecurring(기존 TaskType)의 기본값
    /// - product-decisions.md 3.3: dailyRecurring은 Habit reset 유지
    public static let defaultForDailyRecurring: RecurrenceBehavior = .habitReset

    /// RecurrenceRule 사용 시 기본값
    /// - product-decisions.md 3.3: 반복 규칙 확장 태스크는 Rollover 기본
    public static let defaultForRecurrenceRule: RecurrenceBehavior = .rollover
}

// MARK: - Description

extension RecurrenceBehavior {
    /// 사용자 표시용 라벨 (KR)
    public var labelKR: String {
        switch self {
        case .habitReset: return "습관 모드"
        case .rollover: return "업무 모드"
        }
    }

    /// 사용자 표시용 라벨 (EN)
    public var labelEN: String {
        switch self {
        case .habitReset: return "Habit Mode"
        case .rollover: return "Work Mode"
        }
    }

    /// 사용자 표시용 설명 (KR)
    public var descriptionKR: String {
        switch self {
        case .habitReset:
            return "매일 새로 시작 (미완료 누적 없음)"
        case .rollover:
            return "미완료 시 지연으로 유지"
        }
    }

    /// 사용자 표시용 설명 (EN)
    public var descriptionEN: String {
        switch self {
        case .habitReset:
            return "Fresh start each day (no backlog)"
        case .rollover:
            return "Incomplete stays as overdue"
        }
    }
}

// MARK: - Completion Semantics

extension RecurrenceBehavior {
    /// 미완료가 다음 날에도 유지되는지 여부
    /// - habitReset: false (다음 날 리셋)
    /// - rollover: true (지연으로 유지)
    public var carriesOverIncomplete: Bool {
        switch self {
        case .habitReset: return false
        case .rollover: return true
        }
    }

    /// 지연(overdue) 상태가 발생할 수 있는지 여부
    public var canBeOverdue: Bool {
        switch self {
        case .habitReset: return false
        case .rollover: return true
        }
    }
}
