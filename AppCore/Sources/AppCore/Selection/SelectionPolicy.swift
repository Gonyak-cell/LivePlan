import Foundation

/// 선정 정책
/// - lockscreen.md B 준수
public enum SelectionPolicy: Sendable {
    /// 핀 프로젝트 우선 (기본)
    case pinnedFirst(projectId: String?)

    /// 오늘 요약 (전체 프로젝트)
    case todayOverview
}

// MARK: - Selection Constants

public enum SelectionConstants {
    /// 위젯에 표시할 최대 태스크 수
    public static let widgetTopN = 3

    /// Live Activity에 표시할 최대 태스크 수
    public static let activityTopN = 1

    /// dueSoon 기준 시간 (24시간)
    public static let dueSoonThresholdHours = 24
}
