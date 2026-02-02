import Foundation
import AppCore

/// 전체 데이터 스냅샷
/// - 저장/로드의 단위
/// - data-model.md A2(Section), A3(Tag) 준수
public struct DataSnapshot: Codable, Sendable {
    public var schemaVersion: Int
    public var projects: [Project]
    public var tasks: [Task]
    public var completionLogs: [CompletionLog]
    public var settings: AppSettings

    /// 섹션 목록 (Phase 2.0)
    /// - data-model.md A2 준수
    public var sections: [Section]

    /// 태그 목록 (Phase 2.0)
    /// - data-model.md A3 준수
    public var tags: [Tag]

    /// 저장된 뷰/필터 목록 (Phase 2.0)
    /// - data-model.md A7 준수
    public var savedViews: [SavedView]

    public init(
        schemaVersion: Int = AppSettings.currentSchemaVersion,
        projects: [Project] = [],
        tasks: [Task] = [],
        completionLogs: [CompletionLog] = [],
        settings: AppSettings = .default,
        sections: [Section] = [],
        tags: [Tag] = [],
        savedViews: [SavedView] = []
    ) {
        self.schemaVersion = schemaVersion
        self.projects = projects
        self.tasks = tasks
        self.completionLogs = completionLogs
        self.settings = settings
        self.sections = sections
        self.tags = tags
        self.savedViews = savedViews
    }
}

// MARK: - Empty State

extension DataSnapshot {
    /// 빈 스냅샷 (초기 상태)
    public static let empty = DataSnapshot()

    /// Inbox 포함 초기 스냅샷
    public static func withInbox() -> DataSnapshot {
        DataSnapshot(
            projects: [Project.createInbox()],
            tasks: [],
            completionLogs: [],
            settings: .default,
            sections: [],
            tags: [],
            savedViews: []
        )
    }
}

// MARK: - Migration (Decodable)

extension DataSnapshot {
    /// 커스텀 디코딩 - v1 데이터 호환
    /// - v1에는 sections, tags가 없음
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 필수 필드 (v1부터 존재)
        self.schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        self.projects = try container.decode([Project].self, forKey: .projects)
        self.tasks = try container.decode([Task].self, forKey: .tasks)
        self.completionLogs = try container.decode([CompletionLog].self, forKey: .completionLogs)
        self.settings = try container.decode(AppSettings.self, forKey: .settings)

        // v2 신규 필드 - 없으면 빈 배열
        self.sections = try container.decodeIfPresent([Section].self, forKey: .sections) ?? []
        self.tags = try container.decodeIfPresent([Tag].self, forKey: .tags) ?? []
        self.savedViews = try container.decodeIfPresent([SavedView].self, forKey: .savedViews) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case projects
        case tasks
        case completionLogs
        case settings
        case sections
        case tags
        case savedViews
    }
}

// MARK: - Validation

extension DataSnapshot {
    /// 데이터 정합성 검증
    public func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        // 프로젝트 ID 중복 검사
        let projectIds = projects.map { $0.id }
        if Set(projectIds).count != projectIds.count {
            errors.append(.duplicateProjectId)
        }

        // 태스크 ID 중복 검사
        let taskIds = tasks.map { $0.id }
        if Set(taskIds).count != taskIds.count {
            errors.append(.duplicateTaskId)
        }

        // 섹션 ID 중복 검사 (Phase 2.0)
        let sectionIds = sections.map { $0.id }
        if Set(sectionIds).count != sectionIds.count {
            errors.append(.duplicateSectionId)
        }

        // 태그 ID 중복 검사 (Phase 2.0)
        let tagIds = tags.map { $0.id }
        if Set(tagIds).count != tagIds.count {
            errors.append(.duplicateTagId)
        }

        // CompletionLog 유니크 제약 검사
        let logKeys = completionLogs.map { "\($0.taskId)_\($0.occurrenceKey)" }
        if Set(logKeys).count != logKeys.count {
            errors.append(.duplicateCompletionLog)
        }

        // 태스크의 프로젝트 참조 검사
        let projectIdSet = Set(projectIds)
        for task in tasks {
            if !projectIdSet.contains(task.projectId) {
                errors.append(.orphanedTask(task.id, task.projectId))
            }
        }

        // 섹션의 프로젝트 참조 검사 (Phase 2.0)
        for section in sections {
            if !projectIdSet.contains(section.projectId) {
                errors.append(.orphanedSection(section.id, section.projectId))
            }
        }

        // 태스크의 섹션 참조 검사 (Phase 2.0)
        let sectionIdSet = Set(sectionIds)
        for task in tasks {
            if let sectionId = task.sectionId, !sectionIdSet.contains(sectionId) {
                errors.append(.invalidSectionReference(task.id, sectionId))
            }
        }

        // 태스크의 태그 참조 검사 (Phase 2.0)
        let tagIdSet = Set(tagIds)
        for task in tasks {
            for tagId in task.tagIds {
                if !tagIdSet.contains(tagId) {
                    errors.append(.invalidTagReference(task.id, tagId))
                }
            }
        }

        // 태스크의 blockedByTaskIds 참조 검사 (Phase 2.0)
        let taskIdSet = Set(taskIds)
        for task in tasks {
            for blockedById in task.blockedByTaskIds {
                if !taskIdSet.contains(blockedById) {
                    errors.append(.invalidBlockedByReference(task.id, blockedById))
                }
                if blockedById == task.id {
                    errors.append(.selfBlockingTask(task.id))
                }
            }
        }

        // SavedView ID 중복 검사 (Phase 2.0)
        let savedViewIds = savedViews.map { $0.id }
        if Set(savedViewIds).count != savedViewIds.count {
            errors.append(.duplicateSavedViewId)
        }

        return errors
    }
}

// MARK: - ValidationError

public enum ValidationError: Error, Equatable {
    case duplicateProjectId
    case duplicateTaskId
    case duplicateSectionId
    case duplicateTagId
    case duplicateSavedViewId
    case duplicateCompletionLog
    case orphanedTask(String, String) // taskId, projectId
    case orphanedSection(String, String) // sectionId, projectId
    case invalidSectionReference(String, String) // taskId, sectionId
    case invalidTagReference(String, String) // taskId, tagId
    case invalidBlockedByReference(String, String) // taskId, blockedByTaskId
    case selfBlockingTask(String) // taskId
}
