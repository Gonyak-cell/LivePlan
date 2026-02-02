import Foundation

/// 설정 저장소 프로토콜
/// - architecture.md D1 준수: AppCore는 프로토콜만 정의
/// - data-model.md A8 준수: AppSettings 관리
public protocol SettingsRepository: Sendable {
    /// 현재 설정 로드
    func load() async throws -> AppSettings

    /// 설정 저장
    func save(_ settings: AppSettings) async throws
}
