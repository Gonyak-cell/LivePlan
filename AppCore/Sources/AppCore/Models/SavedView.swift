import Foundation

/// 저장된 뷰 (필터)
/// - data-model.md A7 준수
/// - Todoist 필터 개념을 벤치마크
/// - Built-in(6개) + 사용자 커스텀
public struct SavedView: Identifiable, Codable, Equatable, Sendable {
    // MARK: - Required Fields

    public let id: String
    public var name: String

    // MARK: - Scope

    /// 뷰 스코프
    public var scope: ViewScope

    /// 뷰 타입 (리스트/보드/캘린더)
    public var viewType: ProjectViewType

    /// 필터 정의
    public var definition: FilterDefinition

    // MARK: - Metadata

    /// 생성일
    public let createdAt: Date

    /// 수정일
    public var updatedAt: Date

    /// Built-in 필터인지 여부
    public var isBuiltIn: Bool

    /// 정렬 순서 (낮을수록 앞에 표시)
    public var sortOrder: Int

    // MARK: - Initializer

    public init(
        id: String = UUID().uuidString,
        name: String,
        scope: ViewScope = .global,
        viewType: ProjectViewType = .list,
        definition: FilterDefinition,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.scope = scope
        self.viewType = viewType
        self.definition = definition
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }
}

// MARK: - ViewScope

/// 뷰 스코프
public enum ViewScope: Codable, Equatable, Sendable {
    /// 전역 (모든 프로젝트에서 접근)
    case global

    /// 특정 프로젝트 내
    case project(String)

    /// 전역 스코프인지 여부
    public var isGlobal: Bool {
        if case .global = self {
            return true
        }
        return false
    }

    /// 프로젝트 ID (project 스코프인 경우)
    public var projectId: String? {
        if case .project(let id) = self {
            return id
        }
        return nil
    }
}

// MARK: - Convenience

extension SavedView {
    /// 사용자 정의 필터 생성
    public static func custom(
        name: String,
        definition: FilterDefinition,
        scope: ViewScope = .global,
        viewType: ProjectViewType = .list
    ) -> SavedView {
        SavedView(
            name: name,
            scope: scope,
            viewType: viewType,
            definition: definition,
            isBuiltIn: false
        )
    }

    /// Built-in 필터 생성
    public static func builtIn(
        id: String,
        name: String,
        definition: FilterDefinition,
        sortOrder: Int
    ) -> SavedView {
        SavedView(
            id: id,
            name: name,
            scope: .global,
            viewType: .list,
            definition: definition,
            isBuiltIn: true,
            sortOrder: sortOrder
        )
    }
}

// MARK: - Sorting

extension SavedView: Comparable {
    public static func < (lhs: SavedView, rhs: SavedView) -> Bool {
        // Built-in 먼저, 그 다음 sortOrder
        if lhs.isBuiltIn != rhs.isBuiltIn {
            return lhs.isBuiltIn
        }
        return lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Codable for ViewScope

extension ViewScope {
    private enum CodingKeys: String, CodingKey {
        case type
        case projectId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "global":
            self = .global
        case "project":
            let projectId = try container.decode(String.self, forKey: .projectId)
            self = .project(projectId)
        default:
            self = .global
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .global:
            try container.encode("global", forKey: .type)
        case .project(let projectId):
            try container.encode("project", forKey: .type)
            try container.encode(projectId, forKey: .projectId)
        }
    }
}
