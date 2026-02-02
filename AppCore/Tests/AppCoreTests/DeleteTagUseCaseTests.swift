import XCTest
@testable import AppCore

/// DeleteTagUseCase 테스트
/// - testing.md A1: AppCore 단위 테스트 필수
/// - data-model.md A3: 태그 삭제 시 태스크의 tagIds에서 제거
final class DeleteTagUseCaseTests: XCTestCase {

    private var tagRepository: MockTagRepository!
    private var sut: DeleteTagUseCase!

    override func setUp() {
        super.setUp()
        tagRepository = MockTagRepository()
        sut = DeleteTagUseCase(tagRepository: tagRepository)
    }

    override func tearDown() {
        tagRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Delete

    func testExecute_TagExists_Success() async throws {
        // Given
        let tag = Tag(name: "ToDelete")
        try await tagRepository.save(tag)

        // When
        try await sut.execute(tagId: tag.id)

        // Then: 태그가 삭제됨
        let deletedTag = try await tagRepository.load(id: tag.id)
        XCTAssertNil(deletedTag)
    }

    func testExecute_MultipleTags_OnlyDeletesTarget() async throws {
        // Given: 3개의 태그
        let tag1 = Tag(name: "Tag1")
        let tag2 = Tag(name: "Tag2")
        let tag3 = Tag(name: "Tag3")
        try await tagRepository.save(tag1)
        try await tagRepository.save(tag2)
        try await tagRepository.save(tag3)

        // When: tag2만 삭제
        try await sut.execute(tagId: tag2.id)

        // Then: tag1, tag3는 남아있음
        let allTags = try await tagRepository.loadAll()
        XCTAssertEqual(allTags.count, 2)
        XCTAssertTrue(allTags.contains { $0.id == tag1.id })
        XCTAssertFalse(allTags.contains { $0.id == tag2.id })
        XCTAssertTrue(allTags.contains { $0.id == tag3.id })
    }

    // MARK: - Error Cases

    func testExecute_TagNotFound_ThrowsError() async throws {
        // When/Then
        do {
            try await sut.execute(tagId: "non-existent")
            XCTFail("Expected error")
        } catch let error as DeleteTagError {
            if case .tagNotFound(let id) = error {
                XCTAssertEqual(id, "non-existent")
            } else {
                XCTFail("Expected tagNotFound error")
            }
        }
    }

    // MARK: - Idempotency

    func testExecute_DeleteTwice_SecondThrowsError() async throws {
        // Given
        let tag = Tag(name: "ToDelete")
        try await tagRepository.save(tag)

        // When: 첫 번째 삭제 성공
        try await sut.execute(tagId: tag.id)

        // Then: 두 번째 삭제는 에러
        do {
            try await sut.execute(tagId: tag.id)
            XCTFail("Expected error")
        } catch let error as DeleteTagError {
            if case .tagNotFound = error {
                // success
            } else {
                XCTFail("Expected tagNotFound error")
            }
        }
    }
}

// MARK: - Mock Repository

private final class MockTagRepository: TagRepository, @unchecked Sendable {
    private var tags: [String: Tag] = [:]

    func loadAll() async throws -> [Tag] {
        Array(tags.values)
    }

    func load(id: String) async throws -> Tag? {
        tags[id]
    }

    func load(byName name: String) async throws -> Tag? {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)
        return tags.values.first { $0.normalizedName == normalizedName }
    }

    func save(_ tag: Tag) async throws {
        tags[tag.id] = tag
    }

    func delete(id: String) async throws {
        tags.removeValue(forKey: id)
    }
}
