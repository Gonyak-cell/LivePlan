import Foundation
import AppCore

/// 파일 기반 태그 저장소
/// - TagRepository 프로토콜 구현
/// - data-model.md A3 준수: 태스크의 다대다 분류
public final class FileTagRepository: TagRepository, @unchecked Sendable {
    private let storage: FileBasedStorage

    public init(storage: FileBasedStorage) {
        self.storage = storage
    }

    public func loadAll() async throws -> [Tag] {
        let snapshot = await storage.load()
        return snapshot.tags
    }

    public func load(id: String) async throws -> Tag? {
        let snapshot = await storage.load()
        return snapshot.tags.first { $0.id == id }
    }

    public func load(byName name: String) async throws -> Tag? {
        let snapshot = await storage.load()
        let lowercasedName = name.lowercased()
        return snapshot.tags.first { $0.name.lowercased() == lowercasedName }
    }

    public func save(_ tag: Tag) async throws {
        try await storage.saveTag(tag)
    }

    public func delete(id: String) async throws {
        try await storage.deleteTag(id: id)
    }
}
