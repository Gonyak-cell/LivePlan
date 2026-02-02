import Foundation
import AppCore

/// v1 → v2 마이그레이션
/// - data-model.md D 준수
/// - Task 기본값 적용 (priority P4, workflowState todo)
/// - taskType → recurrenceRule 변환 (dailyRecurring → RecurrenceRule.daily)
/// - Inbox 프로젝트 보장
public struct V1ToV2Migration: Sendable {
    public init() {}

    /// v1 스냅샷을 v2로 마이그레이션
    /// - Parameter snapshot: v1 스냅샷
    /// - Returns: v2 스냅샷
    /// - Throws: MigrationError
    public func migrate(_ snapshot: DataSnapshot) throws -> DataSnapshot {
        guard snapshot.schemaVersion == 1 else {
            throw MigrationError.unknownVersion(snapshot.schemaVersion)
        }

        // 1. 프로젝트: Inbox 보장
        let migratedProjects = migrateProjects(snapshot.projects)

        // 2. 태스크: 기본값 적용 + dailyRecurring → recurrenceRule
        let migratedTasks = migrateTasks(snapshot.tasks)

        // 3. CompletionLog: 이미 occurrenceKey 사용 중 (변환 불필요)
        // v1에서도 occurrenceKey가 있었으므로 그대로 유지

        // 4. Settings: schemaVersion 업데이트
        var migratedSettings = snapshot.settings
        migratedSettings.schemaVersion = 2

        return DataSnapshot(
            schemaVersion: 2,
            projects: migratedProjects,
            tasks: migratedTasks,
            completionLogs: snapshot.completionLogs,
            settings: migratedSettings,
            sections: snapshot.sections,  // v1에는 빈 배열
            tags: snapshot.tags           // v1에는 빈 배열
        )
    }
}

// MARK: - Project Migration

extension V1ToV2Migration {
    /// 프로젝트 마이그레이션: Inbox 보장
    private func migrateProjects(_ projects: [Project]) -> [Project] {
        // Inbox 프로젝트가 없으면 추가
        let hasInbox = projects.contains { $0.isInbox }
        if hasInbox {
            return projects
        }

        var result = projects
        result.append(Project.createInbox())
        return result
    }
}

// MARK: - Task Migration

extension V1ToV2Migration {
    /// 태스크 마이그레이션
    /// - Phase 2 기본값은 Task.init(from decoder:)에서 이미 적용됨
    /// - dailyRecurring → recurrenceRule.daily() 변환
    private func migrateTasks(_ tasks: [Task]) -> [Task] {
        tasks.map { migrateTask($0) }
    }

    private func migrateTask(_ task: Task) -> Task {
        var migrated = task

        // dailyRecurring이면서 recurrenceRule이 없으면 생성
        // (Phase 2에서는 recurrenceRule 기반으로 통합)
        if task.taskType == .dailyRecurring && task.recurrenceRule == nil {
            migrated.recurrenceRule = RecurrenceRule.daily(
                anchorDate: task.createdAt
            )
            // habitReset이 기본 (product-decisions.md 3.3)
            migrated.recurrenceBehavior = .habitReset
        }

        return migrated
    }
}
