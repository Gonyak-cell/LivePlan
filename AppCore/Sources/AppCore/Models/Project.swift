import Foundation

/// 프로젝트 엔티티
/// - data-model.md A1 준수
/// - Phase 2: note 필드 추가 (Notion-lite)
public struct Project: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var title: String
    public var startDate: Date
    public var dueDate: Date?
    public var status: ProjectStatus
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Phase 2 Extensions

    /// 프로젝트 노트 (텍스트/Markdown, Notion-lite)
    public var note: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        startDate: Date,
        dueDate: Date? = nil,
        status: ProjectStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.dueDate = dueDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.note = note
    }
}

// MARK: - Validation

extension Project {
    /// 불변식 검증: dueDate < startDate 금지
    public var isValid: Bool {
        if let dueDate {
            return dueDate >= startDate
        }
        return true
    }
}

// MARK: - ProjectStatus

public enum ProjectStatus: String, Codable, CaseIterable, Sendable {
    case active
    case archived
    case completed
}

extension ProjectStatus {
    /// 활성 상태인지 여부
    public var isActive: Bool {
        self == .active
    }

    /// 잠금화면 후보에서 제외되는 상태인지 여부
    /// - archived/completed는 잠금화면에서 제외 (lockscreen.md)
    public var isExcludedFromLockScreen: Bool {
        self != .active
    }

    /// 사용자 표시용 설명 (KR)
    public var descriptionKR: String {
        switch self {
        case .active: return "활성"
        case .archived: return "보관됨"
        case .completed: return "완료됨"
        }
    }

    /// 사용자 표시용 설명 (EN)
    public var descriptionEN: String {
        switch self {
        case .active: return "Active"
        case .archived: return "Archived"
        case .completed: return "Completed"
        }
    }
}

// MARK: - Inbox Project

extension Project {
    /// 숨김 Inbox 프로젝트 ID (QuickAdd 폴백용)
    public static let inboxProjectId = "inbox"

    /// Inbox 프로젝트 생성
    public static func createInbox() -> Project {
        Project(
            id: inboxProjectId,
            title: "Inbox",
            startDate: Date()
        )
    }

    public var isInbox: Bool {
        id == Self.inboxProjectId
    }
}

// MARK: - Note Convenience

extension Project {
    /// 노트가 있는지 여부
    public var hasNote: Bool {
        guard let note else { return false }
        return !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Codable (Migration Support)

extension Project {
    /// Phase 1 데이터 마이그레이션 지원을 위한 커스텀 디코딩
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        startDate = try container.decode(Date.self, forKey: .startDate)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        status = try container.decode(ProjectStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // Phase 2 fields with defaults for migration
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, startDate, dueDate, status, createdAt, updatedAt, note
    }
}
