import Foundation
import AppCore

/// 파일 기반 태스크 저장소
public final class FileTaskRepository: TaskRepository, @unchecked Sendable {
    private let storage: FileBasedStorage

    public init(storage: FileBasedStorage) {
        self.storage = storage
    }

    public func loadAll() async throws -> [Task] {
        let snapshot = await storage.load()
        return snapshot.tasks
    }

    public func load(id: String) async throws -> Task? {
        let snapshot = await storage.load()
        return snapshot.tasks.first { $0.id == id }
    }

    public func loadByProject(projectId: String) async throws -> [Task] {
        let snapshot = await storage.load()
        return snapshot.tasks.filter { $0.projectId == projectId }
    }

    public func save(_ task: Task) async throws {
        try await storage.saveTask(task)
    }

    public func delete(id: String) async throws {
        try await storage.deleteTask(id: id)
    }

    public func deleteByProject(projectId: String) async throws {
        var snapshot = await storage.load()
        snapshot.tasks.removeAll { $0.projectId == projectId }
        try await storage.save(snapshot)
    }
}
