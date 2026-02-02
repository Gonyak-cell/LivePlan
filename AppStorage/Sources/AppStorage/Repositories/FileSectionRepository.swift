import Foundation
import AppCore

/// 파일 기반 섹션 저장소
/// - SectionRepository 프로토콜 구현
/// - data-model.md A2 준수: 섹션은 프로젝트 내부 그룹
public final class FileSectionRepository: SectionRepository, @unchecked Sendable {
    private let storage: FileBasedStorage

    public init(storage: FileBasedStorage) {
        self.storage = storage
    }

    public func loadAll() async throws -> [Section] {
        let snapshot = await storage.load()
        return snapshot.sections
    }

    public func load(id: String) async throws -> Section? {
        let snapshot = await storage.load()
        return snapshot.sections.first { $0.id == id }
    }

    public func loadByProject(projectId: String) async throws -> [Section] {
        let snapshot = await storage.load()
        return snapshot.sections.filter { $0.projectId == projectId }
    }

    public func save(_ section: Section) async throws {
        try await storage.saveSection(section)
    }

    public func delete(id: String) async throws {
        try await storage.deleteSection(id: id)
    }

    public func deleteByProject(projectId: String) async throws {
        try await storage.deleteSectionsByProject(projectId: projectId)
    }
}
