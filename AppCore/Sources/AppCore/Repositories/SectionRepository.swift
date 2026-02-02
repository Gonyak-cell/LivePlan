import Foundation

/// 섹션 저장소 프로토콜
/// - architecture.md D1 준수: AppCore는 프로토콜만 정의
/// - data-model.md A2: 섹션은 프로젝트 내부 그룹
public protocol SectionRepository: Sendable {
    /// 모든 섹션 조회
    func loadAll() async throws -> [Section]

    /// 특정 섹션 조회
    func load(id: String) async throws -> Section?

    /// 프로젝트별 섹션 조회
    func loadByProject(projectId: String) async throws -> [Section]

    /// 섹션 저장 (생성/수정)
    func save(_ section: Section) async throws

    /// 섹션 삭제
    /// - 소속 태스크는 미분류(sectionId=nil)로 변경됨
    func delete(id: String) async throws

    /// 프로젝트의 모든 섹션 삭제
    func deleteByProject(projectId: String) async throws
}

// MARK: - Convenience

extension SectionRepository {
    /// 프로젝트별 섹션 조회 (정렬됨)
    public func loadByProjectSorted(projectId: String) async throws -> [Section] {
        try await loadByProject(projectId: projectId).sortedByOrder()
    }

    /// 다음 orderIndex 계산
    public func nextOrderIndex(for projectId: String) async throws -> Int {
        let sections = try await loadByProject(projectId: projectId)
        return sections.nextOrderIndex(for: projectId)
    }
}
