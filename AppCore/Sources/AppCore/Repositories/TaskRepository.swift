import Foundation

/// 태스크 저장소 프로토콜
/// - architecture.md D1 준수: AppCore는 프로토콜만 정의
/// - Phase 2: 섹션/태그/우선순위/상태별 조회 추가
public protocol TaskRepository: Sendable {
    /// 모든 태스크 조회
    func loadAll() async throws -> [Task]

    /// 특정 태스크 조회
    func load(id: String) async throws -> Task?

    /// 프로젝트별 태스크 조회
    func loadByProject(projectId: String) async throws -> [Task]

    /// 태스크 저장 (생성/수정)
    func save(_ task: Task) async throws

    /// 태스크 삭제
    func delete(id: String) async throws

    /// 프로젝트의 모든 태스크 삭제
    func deleteByProject(projectId: String) async throws

    // MARK: - Phase 2: Section/Tag/Priority/State Queries

    /// 섹션별 태스크 조회
    func loadBySection(sectionId: String) async throws -> [Task]

    /// 미분류(섹션 없음) 태스크 조회
    func loadWithoutSection(projectId: String) async throws -> [Task]

    /// 태그별 태스크 조회
    func loadByTag(tagId: String) async throws -> [Task]

    /// 우선순위별 태스크 조회
    func loadByPriority(_ priority: Priority) async throws -> [Task]

    /// 워크플로 상태별 태스크 조회
    func loadByWorkflowState(_ state: WorkflowState) async throws -> [Task]
}

// MARK: - Default Implementations

extension TaskRepository {
    /// 섹션별 태스크 조회 (기본 구현)
    public func loadBySection(sectionId: String) async throws -> [Task] {
        try await loadAll().filter { $0.sectionId == sectionId }
    }

    /// 미분류 태스크 조회 (기본 구현)
    public func loadWithoutSection(projectId: String) async throws -> [Task] {
        try await loadByProject(projectId: projectId).filter { $0.sectionId == nil }
    }

    /// 태그별 태스크 조회 (기본 구현)
    public func loadByTag(tagId: String) async throws -> [Task] {
        try await loadAll().filter { $0.tagIds.contains(tagId) }
    }

    /// 우선순위별 태스크 조회 (기본 구현)
    public func loadByPriority(_ priority: Priority) async throws -> [Task] {
        try await loadAll().filter { $0.priority == priority }
    }

    /// 워크플로 상태별 태스크 조회 (기본 구현)
    public func loadByWorkflowState(_ state: WorkflowState) async throws -> [Task] {
        try await loadAll().filter { $0.workflowState == state }
    }

    /// 활성 태스크만 조회 (todo/doing)
    public func loadActive() async throws -> [Task] {
        try await loadAll().filter { $0.isActive }
    }

    /// 블로킹된 태스크 조회
    public func loadBlocked() async throws -> [Task] {
        try await loadAll().filter { $0.isBlocked }
    }

    /// 진행 중인 태스크 조회
    public func loadInProgress() async throws -> [Task] {
        try await loadByWorkflowState(.doing)
    }

    /// 고우선순위(P1) 태스크 조회
    public func loadHighPriority() async throws -> [Task] {
        try await loadByPriority(.p1)
    }
}
