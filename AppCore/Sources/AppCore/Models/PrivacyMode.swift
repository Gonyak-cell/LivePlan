import Foundation

/// 프라이버시 모드
/// - product-decisions.md 2.1/2.2 준수
/// - 기본값: Level 1 (Masked)
public enum PrivacyMode: Int, Codable, CaseIterable, Sendable {
    /// Level 0: 제목 원문 (길이 제한)
    case visible = 0

    /// Level 1: 프로젝트명 숨김 + 태스크명 축약/익명 + 카운트 (기본값)
    case masked = 1

    /// Level 2: 카운트/진척률만, 제목 미표시
    case hidden = 2

    /// 기본값 (Level 1)
    public static let defaultMode: PrivacyMode = .masked
}

// MARK: - Description

extension PrivacyMode {
    /// 사용자 표시용 설명 (KR)
    public var descriptionKR: String {
        switch self {
        case .visible:
            return "제목 표시"
        case .masked:
            return "제목 숨김 (기본)"
        case .hidden:
            return "숫자만 표시"
        }
    }

    /// 사용자 표시용 설명 (EN)
    public var descriptionEN: String {
        switch self {
        case .visible:
            return "Show titles"
        case .masked:
            return "Hide titles (default)"
        case .hidden:
            return "Numbers only"
        }
    }
}
