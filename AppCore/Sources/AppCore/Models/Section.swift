import Foundation

/// 섹션 엔티티 (프로젝트 내부 그룹)
/// - data-model.md A2 준수
/// - Todoist 섹션/Asana 섹션 역할 (리스트 그룹핑)
public struct Section: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var projectId: String
    public var title: String
    public var orderIndex: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        projectId: String,
        title: String,
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Sorting

extension Section: Comparable {
    public static func < (lhs: Section, rhs: Section) -> Bool {
        if lhs.orderIndex != rhs.orderIndex {
            return lhs.orderIndex < rhs.orderIndex
        }
        return lhs.createdAt < rhs.createdAt
    }
}

// MARK: - Convenience

extension Section {
    /// 동일 프로젝트 소속인지 확인
    public func belongsTo(projectId: String) -> Bool {
        self.projectId == projectId
    }
}

// MARK: - Array Extensions

extension Array where Element == Section {
    /// 프로젝트별 필터링
    public func forProject(_ projectId: String) -> [Section] {
        filter { $0.projectId == projectId }
    }

    /// 정렬된 순서로 반환
    public func sortedByOrder() -> [Section] {
        sorted()
    }

    /// 다음 orderIndex 계산
    public func nextOrderIndex(for projectId: String) -> Int {
        let projectSections = forProject(projectId)
        guard let maxIndex = projectSections.map(\.orderIndex).max() else {
            return 0
        }
        return maxIndex + 1
    }
}
