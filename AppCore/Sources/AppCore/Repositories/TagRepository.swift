import Foundation

/// 태그 저장소 프로토콜
/// - architecture.md D1 준수: AppCore는 프로토콜만 정의
/// - data-model.md A3: 태스크의 다대다 분류
public protocol TagRepository: Sendable {
    /// 모든 태그 조회
    func loadAll() async throws -> [Tag]

    /// 특정 태그 조회
    func load(id: String) async throws -> Tag?

    /// 이름으로 태그 조회 (대소문자 무시)
    func load(byName name: String) async throws -> Tag?

    /// 태그 저장 (생성/수정)
    func save(_ tag: Tag) async throws

    /// 태그 삭제
    /// - 태스크의 tagIds에서 해당 ID 제거됨
    func delete(id: String) async throws
}

// MARK: - Convenience

extension TagRepository {
    /// 이름으로 태그 찾기 또는 생성
    /// - data-model.md: name은 대소문자 무시 유니크 권장
    public func getOrCreate(name: String) async throws -> Tag {
        if let existing = try await load(byName: name) {
            return existing
        }
        let tag = Tag(name: name)
        try await save(tag)
        return tag
    }

    /// 모든 태그 조회 (이름순 정렬)
    public func loadAllSorted() async throws -> [Tag] {
        try await loadAll().sortedByName()
    }

    /// ID 목록으로 태그 조회
    public func load(byIds ids: [String]) async throws -> [Tag] {
        let idSet = Set(ids)
        return try await loadAll().filter { idSet.contains($0.id) }
    }
}
