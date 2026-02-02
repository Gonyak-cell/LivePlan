import Foundation

/// 프로젝트 저장소 프로토콜
/// - architecture.md D1 준수: AppCore는 프로토콜만 정의
public protocol ProjectRepository: Sendable {
    /// 모든 프로젝트 조회
    func loadAll() async throws -> [Project]

    /// 특정 프로젝트 조회
    func load(id: String) async throws -> Project?

    /// 프로젝트 저장 (생성/수정)
    func save(_ project: Project) async throws

    /// 프로젝트 삭제
    func delete(id: String) async throws

    /// 활성 프로젝트만 조회 (archived/completed 제외)
    func loadActive() async throws -> [Project]
}

// MARK: - Default Implementation

extension ProjectRepository {
    /// 활성 프로젝트만 조회 (기본 구현)
    public func loadActive() async throws -> [Project] {
        try await loadAll().filter { $0.status == .active }
    }

    /// Inbox 프로젝트 조회 또는 생성
    public func getOrCreateInbox() async throws -> Project {
        if let inbox = try await load(id: Project.inboxProjectId) {
            return inbox
        }
        let inbox = Project.createInbox()
        try await save(inbox)
        return inbox
    }
}
