import Foundation

/// 저장된 뷰 저장소 프로토콜
/// - architecture.md D1 준수: AppCore는 프로토콜만 정의
/// - data-model.md A7: 저장된 뷰/필터
public protocol SavedViewRepository: Sendable {
    /// 모든 저장된 뷰 조회
    func loadAll() async throws -> [SavedView]

    /// 특정 저장된 뷰 조회
    func load(id: String) async throws -> SavedView?

    /// 전역 뷰만 조회
    func loadGlobal() async throws -> [SavedView]

    /// 프로젝트별 뷰 조회
    func loadByProject(projectId: String) async throws -> [SavedView]

    /// Built-in 뷰만 조회
    func loadBuiltIn() async throws -> [SavedView]

    /// 커스텀 뷰만 조회
    func loadCustom() async throws -> [SavedView]

    /// 저장된 뷰 저장 (생성/수정)
    func save(_ view: SavedView) async throws

    /// 저장된 뷰 삭제
    /// - Built-in 뷰는 삭제 불가
    func delete(id: String) async throws

    /// 프로젝트의 모든 뷰 삭제
    func deleteByProject(projectId: String) async throws
}

// MARK: - Default Implementations

extension SavedViewRepository {
    /// 전역 뷰만 조회 (기본 구현)
    public func loadGlobal() async throws -> [SavedView] {
        try await loadAll().filter { $0.scope.isGlobal }
    }

    /// 프로젝트별 뷰 조회 (기본 구현)
    public func loadByProject(projectId: String) async throws -> [SavedView] {
        try await loadAll().filter { $0.scope.projectId == projectId }
    }

    /// Built-in 뷰만 조회 (기본 구현)
    public func loadBuiltIn() async throws -> [SavedView] {
        try await loadAll().filter { $0.isBuiltIn }
    }

    /// 커스텀 뷰만 조회 (기본 구현)
    public func loadCustom() async throws -> [SavedView] {
        try await loadAll().filter { !$0.isBuiltIn }
    }

    /// 모든 뷰 조회 (정렬됨)
    public func loadAllSorted() async throws -> [SavedView] {
        try await loadAll().sorted()
    }

    /// 이름으로 뷰 조회
    public func load(byName name: String) async throws -> SavedView? {
        try await loadAll().first { $0.name.lowercased() == name.lowercased() }
    }
}
