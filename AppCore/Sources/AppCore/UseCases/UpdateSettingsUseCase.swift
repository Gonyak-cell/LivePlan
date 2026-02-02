import Foundation

/// 설정 업데이트 Use Case
/// - architecture.md B3 준수: 도메인 로직은 AppCore에만
/// - data-model.md A8 준수: AppSettings 필드 업데이트
public struct UpdateSettingsUseCase: Sendable {
    private let settingsRepository: any SettingsRepository

    public init(settingsRepository: any SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    /// 설정 업데이트
    /// - Parameters:
    ///   - privacyMode: 새 프라이버시 모드 (nil이면 변경 안 함)
    ///   - pinnedProjectId: 새 핀 프로젝트 ID (.some(id)면 설정, .some(nil)이면 제거, nil이면 변경 안 함)
    ///   - lockscreenSelectionMode: 새 잠금화면 선택 모드 (nil이면 변경 안 함)
    ///   - defaultProjectViewType: 새 기본 프로젝트 뷰 타입 (nil이면 변경 안 함)
    ///   - quickAddParsingEnabled: 새 QuickAdd 파싱 활성화 여부 (nil이면 변경 안 함)
    /// - Returns: 업데이트된 설정
    public func execute(
        privacyMode: PrivacyMode? = nil,
        pinnedProjectId: OptionalValue<String>? = nil,
        lockscreenSelectionMode: LockscreenSelectionMode? = nil,
        defaultProjectViewType: ProjectViewType? = nil,
        quickAddParsingEnabled: Bool? = nil
    ) async throws -> AppSettings {
        // 1. 현재 설정 로드
        var settings = try await settingsRepository.load()

        // 2. 프라이버시 모드 수정
        if let newPrivacyMode = privacyMode {
            settings.privacyMode = newPrivacyMode
        }

        // 3. 핀 프로젝트 ID 수정
        if let pinnedValue = pinnedProjectId {
            settings.pinnedProjectId = pinnedValue.value
        }

        // 4. 잠금화면 선택 모드 수정
        if let newMode = lockscreenSelectionMode {
            settings.lockscreenSelectionMode = newMode
        }

        // 5. 기본 프로젝트 뷰 타입 수정
        if let newViewType = defaultProjectViewType {
            settings.defaultProjectViewType = newViewType
        }

        // 6. QuickAdd 파싱 활성화 수정
        if let newParsingEnabled = quickAddParsingEnabled {
            settings.quickAddParsingEnabled = newParsingEnabled
        }

        // 7. 저장
        try await settingsRepository.save(settings)

        return settings
    }
}

// MARK: - Errors

public enum UpdateSettingsError: Error, LocalizedError, Equatable {
    case loadFailed
    case saveFailed

    public var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Failed to load settings"
        case .saveFailed:
            return "Failed to save settings"
        }
    }
}
