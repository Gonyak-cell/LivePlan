import Foundation

/// 프로젝트 뷰 타입
/// - data-model.md A8 / product-decisions.md 1.2 준수
/// - 프로젝트 내부에서 태스크를 보는 방식
public enum ProjectViewType: String, Codable, CaseIterable, Sendable {
    /// 리스트 뷰 (기본값)
    case list

    /// 보드 뷰 (상태 컬럼)
    case board

    /// 캘린더 뷰 (dueAt 기준)
    case calendar

    /// 기본값
    public static let defaultViewType: ProjectViewType = .list
}

// MARK: - Description

extension ProjectViewType {
    /// 사용자 표시용 라벨 (KR)
    public var labelKR: String {
        switch self {
        case .list: return "리스트"
        case .board: return "보드"
        case .calendar: return "캘린더"
        }
    }

    /// 사용자 표시용 라벨 (EN)
    public var labelEN: String {
        switch self {
        case .list: return "List"
        case .board: return "Board"
        case .calendar: return "Calendar"
        }
    }

    /// SF Symbol 아이콘 이름
    public var iconName: String {
        switch self {
        case .list: return "list.bullet"
        case .board: return "rectangle.split.3x1"
        case .calendar: return "calendar"
        }
    }
}
