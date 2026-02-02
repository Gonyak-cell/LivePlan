import Foundation
import AppCore

/// 파일 기반 완료 로그 저장소
public final class FileCompletionLogRepository: CompletionLogRepository, @unchecked Sendable {
    private let storage: FileBasedStorage

    public init(storage: FileBasedStorage) {
        self.storage = storage
    }

    public func loadAll() async throws -> [CompletionLog] {
        let snapshot = await storage.load()
        return snapshot.completionLogs
    }

    public func loadByTask(taskId: String) async throws -> [CompletionLog] {
        let snapshot = await storage.load()
        return snapshot.completionLogs.filter { $0.taskId == taskId }
    }

    public func load(taskId: String, occurrenceKey: String) async throws -> CompletionLog? {
        let snapshot = await storage.load()
        return snapshot.completionLogs.first {
            $0.taskId == taskId && $0.occurrenceKey == occurrenceKey
        }
    }

    public func save(_ log: CompletionLog) async throws {
        try await storage.saveCompletionLog(log)
    }

    public func delete(taskId: String, occurrenceKey: String) async throws {
        var snapshot = await storage.load()
        snapshot.completionLogs.removeAll {
            $0.taskId == taskId && $0.occurrenceKey == occurrenceKey
        }
        try await storage.save(snapshot)
    }

    public func deleteByTask(taskId: String) async throws {
        var snapshot = await storage.load()
        snapshot.completionLogs.removeAll { $0.taskId == taskId }
        try await storage.save(snapshot)
    }
}
