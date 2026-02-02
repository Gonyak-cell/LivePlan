import Foundation
import AppCore

/// 파일 기반 프로젝트 저장소
public final class FileProjectRepository: ProjectRepository, @unchecked Sendable {
    private let storage: FileBasedStorage

    public init(storage: FileBasedStorage) {
        self.storage = storage
    }

    public func loadAll() async throws -> [Project] {
        let snapshot = await storage.load()
        return snapshot.projects
    }

    public func load(id: String) async throws -> Project? {
        let snapshot = await storage.load()
        return snapshot.projects.first { $0.id == id }
    }

    public func save(_ project: Project) async throws {
        try await storage.saveProject(project)
    }

    public func delete(id: String) async throws {
        try await storage.deleteProject(id: id)
    }

    public func loadActive() async throws -> [Project] {
        let snapshot = await storage.load()
        return snapshot.projects.filter { $0.status == .active }
    }
}
