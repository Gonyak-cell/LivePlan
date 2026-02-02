import Foundation
import AppCore

/// 마이그레이션 엔진
/// - testing.md A2 준수: schemaVersion 마이그레이션 테스트 필수
public struct MigrationEngine: Sendable {
    public init() {}

    /// 스냅샷 마이그레이션
    /// - Parameter snapshot: 원본 스냅샷
    /// - Returns: 마이그레이션된 스냅샷
    public func migrate(_ snapshot: DataSnapshot) async throws -> DataSnapshot {
        var current = snapshot

        // 버전별 순차 마이그레이션
        while current.schemaVersion < AppSettings.currentSchemaVersion {
            current = try await migrateStep(current)
        }

        return current
    }

    /// 단일 버전 마이그레이션
    private func migrateStep(_ snapshot: DataSnapshot) async throws -> DataSnapshot {
        switch snapshot.schemaVersion {
        case 1:
            // v1 -> v2 마이그레이션
            // - Inbox 프로젝트 보장
            // - Task 기본값 (priority P4, workflowState todo)
            // - dailyRecurring → recurrenceRule.daily()
            let migration = V1ToV2Migration()
            do {
                return try migration.migrate(snapshot)
            } catch {
                throw StorageError.migrationFailed(from: 1, to: 2, error)
            }

        default:
            // 알 수 없는 버전
            throw StorageError.migrationFailed(
                from: snapshot.schemaVersion,
                to: snapshot.schemaVersion + 1,
                MigrationError.unknownVersion(snapshot.schemaVersion)
            )
        }
    }
}

// MARK: - MigrationError

public enum MigrationError: Error, LocalizedError {
    case unknownVersion(Int)
    case dataCorruption(String)

    public var errorDescription: String? {
        switch self {
        case .unknownVersion(let version):
            return "Unknown schema version: \(version)"
        case .dataCorruption(let detail):
            return "Data corruption detected: \(detail)"
        }
    }
}
