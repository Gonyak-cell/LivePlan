import Foundation
import AppCore

/// 파일 기반 설정 저장소
public final class FileSettingsRepository: SettingsRepository, @unchecked Sendable {
    private let storage: FileBasedStorage

    public init(storage: FileBasedStorage) {
        self.storage = storage
    }

    public func load() async throws -> AppSettings {
        let snapshot = await storage.load()
        return snapshot.settings
    }

    public func save(_ settings: AppSettings) async throws {
        try await storage.saveSettings(settings)
    }
}
