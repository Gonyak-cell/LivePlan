import Foundation
import AppCore

/// 파일 기반 저장된 뷰 저장소
/// - SavedViewRepository 프로토콜 구현
/// - data-model.md A7 준수: 저장된 뷰/필터
public final class FileSavedViewRepository: SavedViewRepository, @unchecked Sendable {
    private let storage: FileBasedStorage

    public init(storage: FileBasedStorage) {
        self.storage = storage
    }

    public func loadAll() async throws -> [SavedView] {
        let snapshot = await storage.load()
        return snapshot.savedViews
    }

    public func load(id: String) async throws -> SavedView? {
        let snapshot = await storage.load()
        return snapshot.savedViews.first { $0.id == id }
    }

    public func loadGlobal() async throws -> [SavedView] {
        let snapshot = await storage.load()
        return snapshot.savedViews.filter { $0.scope.isGlobal }
    }

    public func loadByProject(projectId: String) async throws -> [SavedView] {
        let snapshot = await storage.load()
        return snapshot.savedViews.filter { $0.scope.projectId == projectId }
    }

    public func loadBuiltIn() async throws -> [SavedView] {
        let snapshot = await storage.load()
        return snapshot.savedViews.filter { $0.isBuiltIn }
    }

    public func loadCustom() async throws -> [SavedView] {
        let snapshot = await storage.load()
        return snapshot.savedViews.filter { !$0.isBuiltIn }
    }

    public func save(_ view: SavedView) async throws {
        try await storage.saveSavedView(view)
    }

    public func delete(id: String) async throws {
        try await storage.deleteSavedView(id: id)
    }

    public func deleteByProject(projectId: String) async throws {
        try await storage.deleteSavedViewsByProject(projectId: projectId)
    }
}
