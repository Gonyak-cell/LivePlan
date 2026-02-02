import XCTest
@testable import AppCore

/// UpdateTagUseCase 테스트
/// - testing.md A1: AppCore 단위 테스트 필수
/// - data-model.md A3: 태그의 다대다 분류
final class UpdateTagUseCaseTests: XCTestCase {

    private var tagRepository: MockTagRepository!
    private var sut: UpdateTagUseCase!

    override func setUp() {
        super.setUp()
        tagRepository = MockTagRepository()
        sut = UpdateTagUseCase(tagRepository: tagRepository)
    }

    override func tearDown() {
        tagRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Update

    func testExecute_UpdateName_Success() async throws {
        // Given: 기존 태그
        let existingTag = Tag(name: "OldName", colorToken: "blue")
        try await tagRepository.save(existingTag)

        // When
        let updatedTag = try await sut.execute(tagId: existingTag.id, name: "NewName")

        // Then
        XCTAssertEqual(updatedTag.name, "NewName")
        XCTAssertEqual(updatedTag.colorToken, "blue") // 색상 유지
    }

    func testExecute_UpdateColorToken_Success() async throws {
        // Given
        let existingTag = Tag(name: "TagName", colorToken: "blue")
        try await tagRepository.save(existingTag)

        // When
        let updatedTag = try await sut.execute(tagId: existingTag.id, colorToken: .some("red"))

        // Then
        XCTAssertEqual(updatedTag.name, "TagName") // 이름 유지
        XCTAssertEqual(updatedTag.colorToken, "red")
    }

    func testExecute_UpdateBoth_Success() async throws {
        // Given
        let existingTag = Tag(name: "OldName", colorToken: "blue")
        try await tagRepository.save(existingTag)

        // When
        let updatedTag = try await sut.execute(
            tagId: existingTag.id,
            name: "NewName",
            colorToken: .some("red")
        )

        // Then
        XCTAssertEqual(updatedTag.name, "NewName")
        XCTAssertEqual(updatedTag.colorToken, "red")
    }

    func testExecute_RemoveColorToken_Success() async throws {
        // Given
        let existingTag = Tag(name: "TagName", colorToken: "blue")
        try await tagRepository.save(existingTag)

        // When: colorToken을 nil로 설정
        let updatedTag = try await sut.execute(tagId: existingTag.id, colorToken: .some(nil))

        // Then
        XCTAssertNil(updatedTag.colorToken)
    }

    func testExecute_UpdatedAtIsSet() async throws {
        // Given
        let existingTag = Tag(name: "TagName")
        try await tagRepository.save(existingTag)
        let originalUpdatedAt = existingTag.updatedAt

        // 시간 차이를 위해 잠시 대기
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01초

        // When
        let updatedTag = try await sut.execute(tagId: existingTag.id, name: "NewName")

        // Then
        XCTAssertGreaterThan(updatedTag.updatedAt, originalUpdatedAt)
    }

    func testExecute_TrimmedName() async throws {
        // Given
        let existingTag = Tag(name: "TagName")
        try await tagRepository.save(existingTag)

        // When
        let updatedTag = try await sut.execute(tagId: existingTag.id, name: "  Trimmed  ")

        // Then
        XCTAssertEqual(updatedTag.name, "Trimmed")
    }

    // MARK: - Error Cases

    func testExecute_TagNotFound_ThrowsError() async throws {
        // When/Then
        do {
            _ = try await sut.execute(tagId: "non-existent", name: "NewName")
            XCTFail("Expected error")
        } catch let error as UpdateTagError {
            if case .tagNotFound(let id) = error {
                XCTAssertEqual(id, "non-existent")
            } else {
                XCTFail("Expected tagNotFound error")
            }
        }
    }

    func testExecute_EmptyName_ThrowsError() async throws {
        // Given
        let existingTag = Tag(name: "TagName")
        try await tagRepository.save(existingTag)

        // When/Then
        do {
            _ = try await sut.execute(tagId: existingTag.id, name: "")
            XCTFail("Expected error")
        } catch let error as UpdateTagError {
            XCTAssertEqual(error, .emptyName)
        }
    }

    func testExecute_WhitespaceOnlyName_ThrowsError() async throws {
        // Given
        let existingTag = Tag(name: "TagName")
        try await tagRepository.save(existingTag)

        // When/Then
        do {
            _ = try await sut.execute(tagId: existingTag.id, name: "   ")
            XCTFail("Expected error")
        } catch let error as UpdateTagError {
            XCTAssertEqual(error, .emptyName)
        }
    }

    func testExecute_DuplicateName_ThrowsError() async throws {
        // Given: 두 개의 태그
        let tag1 = Tag(name: "Tag1")
        let tag2 = Tag(name: "Tag2")
        try await tagRepository.save(tag1)
        try await tagRepository.save(tag2)

        // When/Then: tag2의 이름을 tag1과 같게 변경 시도
        do {
            _ = try await sut.execute(tagId: tag2.id, name: "Tag1")
            XCTFail("Expected error")
        } catch let error as UpdateTagError {
            if case .duplicateName(let existingTag) = error {
                XCTAssertEqual(existingTag.id, tag1.id)
            } else {
                XCTFail("Expected duplicateName error")
            }
        }
    }

    func testExecute_DuplicateName_CaseInsensitive() async throws {
        // Given
        let tag1 = Tag(name: "work")
        let tag2 = Tag(name: "personal")
        try await tagRepository.save(tag1)
        try await tagRepository.save(tag2)

        // When/Then: 대문자로 중복 시도
        do {
            _ = try await sut.execute(tagId: tag2.id, name: "WORK")
            XCTFail("Expected error")
        } catch let error as UpdateTagError {
            if case .duplicateName = error {
                // success
            } else {
                XCTFail("Expected duplicateName error")
            }
        }
    }

    // MARK: - Self-Update (Same Name)

    func testExecute_SameName_NoError() async throws {
        // Given: 자기 자신의 이름으로 업데이트
        let existingTag = Tag(name: "SameName")
        try await tagRepository.save(existingTag)

        // When: 같은 이름으로 업데이트 (색상만 변경)
        let updatedTag = try await sut.execute(
            tagId: existingTag.id,
            name: "SameName",
            colorToken: .some("red")
        )

        // Then: 에러 없이 성공
        XCTAssertEqual(updatedTag.name, "SameName")
        XCTAssertEqual(updatedTag.colorToken, "red")
    }

    func testExecute_SameNameDifferentCase_NoError() async throws {
        // Given
        let existingTag = Tag(name: "MyTag")
        try await tagRepository.save(existingTag)

        // When: 같은 이름, 다른 대소문자로 업데이트
        let updatedTag = try await sut.execute(tagId: existingTag.id, name: "mytag")

        // Then: 에러 없이 성공 (자기 자신이므로)
        XCTAssertEqual(updatedTag.name, "mytag")
    }

    // MARK: - Persistence

    func testExecute_ChangesArePersisted() async throws {
        // Given
        let existingTag = Tag(name: "Original")
        try await tagRepository.save(existingTag)

        // When
        _ = try await sut.execute(tagId: existingTag.id, name: "Updated")

        // Then: 저장소에서 확인
        let savedTag = try await tagRepository.load(id: existingTag.id)
        XCTAssertEqual(savedTag?.name, "Updated")
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
