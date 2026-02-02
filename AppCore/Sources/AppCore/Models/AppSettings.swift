import Foundation

/// 앱 설정
/// - data-model.md A8 준수
public struct AppSettings: Codable, Equatable, Sendable {
    /// 스키마 버전 (마이그레이션용)
    public var schemaVersion: Int

    /// 프라이버시 모드 (기본: Level 1)
    public var privacyMode: PrivacyMode

    /// 대표(핀) 프로젝트 ID
    public var pinnedProjectId: String?

    /// 잠금화면 선택 모드
    public var lockscreenSelectionMode: LockscreenSelectionMode

    /// 기본 프로젝트 뷰 타입 (Phase 2.0)
    /// - product-decisions.md 1.2: list/board/calendar 중 기본 list
    public var defaultProjectViewType: ProjectViewType

    /// QuickAdd 파싱 활성화 (Phase 2.0)
    /// - product-decisions.md 5: 빠른 입력 토큰 파싱
    public var quickAddParsingEnabled: Bool

    public init(
        schemaVersion: Int = AppSettings.currentSchemaVersion,
        privacyMode: PrivacyMode = .defaultMode,
        pinnedProjectId: String? = nil,
        lockscreenSelectionMode: LockscreenSelectionMode = .pinnedFirst,
        defaultProjectViewType: ProjectViewType = .defaultViewType,
        quickAddParsingEnabled: Bool = true
    ) {
        self.schemaVersion = schemaVersion
        self.privacyMode = privacyMode
        self.pinnedProjectId = pinnedProjectId
        self.lockscreenSelectionMode = lockscreenSelectionMode
        self.defaultProjectViewType = defaultProjectViewType
        self.quickAddParsingEnabled = quickAddParsingEnabled
    }
}

// MARK: - LockscreenSelectionMode

/// 잠금화면 선택 모드
/// - lockscreen.md B 준수
public enum LockscreenSelectionMode: String, Codable, CaseIterable, Sendable {
    /// 핀 프로젝트 우선 (기본)
    case pinnedFirst

    /// 오늘 요약
    case todayOverview

    /// 자동 (핀 있으면 핀, 없으면 오늘)
    case auto
}

// MARK: - Defaults

extension AppSettings {
    /// 기본 설정
    public static let `default` = AppSettings()

    /// 현재 스키마 버전 (Phase 2.0)
    public static let currentSchemaVersion = 2
}

// MARK: - Migration (Decodable)

extension AppSettings {
    /// 커스텀 디코딩 - 기존 v1 데이터 호환
    /// - v1에는 defaultProjectViewType, quickAddParsingEnabled가 없음
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 필수 필드 (v1부터 존재)
        self.schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        self.privacyMode = try container.decode(PrivacyMode.self, forKey: .privacyMode)
        self.pinnedProjectId = try container.decodeIfPresent(String.self, forKey: .pinnedProjectId)
        self.lockscreenSelectionMode = try container.decode(LockscreenSelectionMode.self, forKey: .lockscreenSelectionMode)

        // v2 신규 필드 - 없으면 기본값 사용
        self.defaultProjectViewType = try container.decodeIfPresent(ProjectViewType.self, forKey: .defaultProjectViewType) ?? .defaultViewType
        self.quickAddParsingEnabled = try container.decodeIfPresent(Bool.self, forKey: .quickAddParsingEnabled) ?? true
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case privacyMode
        case pinnedProjectId
        case lockscreenSelectionMode
        case defaultProjectViewType
        case quickAddParsingEnabled
    }
}
