import XCTest
@testable import AppCore

/// AddTagUseCase 테스트
/// - testing.md A1: AppCore 단위 테스트 필수
/// - data-model.md A3: 태그의 다대다 분류
final class AddTagUseCaseTests: XCTestCase {

    private var tagRepository: MockTagRepository!
    private var sut: AddTagUseCase!

    override func setUp() {
        super.setUp()
        tagRepository = MockTagRepository()
        sut = AddTagUseCase(tagRepository: tagRepository)
    }

    override func tearDown() {
        tagRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Tag Creation

    func testExecute_BasicTag_Success() async throws {
        // When
        let tag = try await sut.execute(name: "Work")

        // Then
        XCTAssertEqual(tag.name, "Work")
        XCTAssertNil(tag.colorToken)
    }

    func testExecute_TrimmedName() async throws {
        // When
        let tag = try await sut.execute(name: "  Trimmed Name  ")

        // Then
        XCTAssertEqual(tag.name, "Trimmed Name")
    }

    func testExecute_WithColorToken() async throws {
        // When
        let tag = try await sut.execute(name: "Important", colorToken: "red")

        // Then
        XCTAssertEqual(tag.name, "Important")
        XCTAssertEqual(tag.colorToken, "red")
    }

    // MARK: - Error Cases

    func testExecute_EmptyName_ThrowsError() async throws {
        // When/Then
        do {
            _ = try await sut.execute(name: "")
            XCTFail("Expected error")
        } catch let error as AddTagError {
            XCTAssertEqual(error, .emptyName)
        }
    }

    func testExecute_WhitespaceOnlyName_ThrowsError() async throws {
        // When/Then
        do {
            _ = try await sut.execute(name: "   ")
            XCTFail("Expected error")
        } catch let error as AddTagError {
            XCTAssertEqual(error, .emptyName)
        }
    }

    func testExecute_DuplicateName_ThrowsError() async throws {
        // Given: 이미 존재하는 태그
        let existingTag = Tag(name: "Work")
        try await tagRepository.save(existingTag)

        // When/Then
        do {
            _ = try await sut.execute(name: "Work")
            XCTFail("Expected error")
        } catch let error as AddTagError {
            if case .duplicateName(let tag) = error {
                XCTAssertEqual(tag.id, existingTag.id)
            } else {
                XCTFail("Expected duplicateName error")
            }
        }
    }

    func testExecute_DuplicateName_CaseInsensitive() async throws {
        // Given: 소문자로 태그 생성
        let existingTag = Tag(name: "work")
        try await tagRepository.save(existingTag)

        // When/Then: 대문자로 시도
        do {
            _ = try await sut.execute(name: "WORK")
            XCTFail("Expected error")
        } catch let error as AddTagError {
            if case .duplicateName(let tag) = error {
                XCTAssertEqual(tag.id, existingTag.id)
            } else {
                XCTFail("Expected duplicateName error")
            }
        }
    }

    func testExecute_DuplicateName_MixedCase() async throws {
        // Given: 혼합 대소문자로 태그 생성
        let existingTag = Tag(name: "WorkLife")
        try await tagRepository.save(existingTag)

        // When/Then: 다른 대소문자 조합으로 시도
        do {
            _ = try await sut.execute(name: "worklife")
            XCTFail("Expected error")
        } catch let error as AddTagError {
            if case .duplicateName = error {
                // success
            } else {
                XCTFail("Expected duplicateName error")
            }
        }
    }

    // MARK: - Persistence

    func testExecute_TagIsSaved() async throws {
        // When
        let tag = try await sut.execute(name: "Saved Tag")

        // Then: 저장소에 저장되었는지 확인
        let savedTag = try await tagRepository.load(id: tag.id)
        XCTAssertNotNil(savedTag)
        XCTAssertEqual(savedTag?.name, "Saved Tag")
    }

    func testExecute_MultipleTags_AllSaved() async throws {
        // When: 3개의 태그 생성
        let tag1 = try await sut.execute(name: "Tag1")
        let tag2 = try await sut.execute(name: "Tag2")
        let tag3 = try await sut.execute(name: "Tag3")

        // Then: 모두 저장됨
        let allTags = try await tagRepository.loadAll()
        XCTAssertEqual(allTags.count, 3)
        XCTAssertTrue(allTags.contains { $0.id == tag1.id })
        XCTAssertTrue(allTags.contains { $0.id == tag2.id })
        XCTAssertTrue(allTags.contains { $0.id == tag3.id })
    }

    // MARK: - Color Token Variants

    func testExecute_AllDefaultColorTokens() async throws {
        // When: 기본 색상 토큰들로 태그 생성
        for (index, colorToken) in Tag.defaultColorTokens.enumerated() {
            let tag = try await sut.execute(
                name: "Tag\(index)",
                colorToken: colorToken
            )
            XCTAssertEqual(tag.colorToken, colorToken)
        }

        // Then: 모든 태그 저장됨
        let allTags = try await tagRepository.loadAll()
        XCTAssertEqual(allTags.count, Tag.defaultColorTokens.count)
    }

    func testExecute_CustomColorToken() async throws {
        // When: 커스텀 색상 토큰 (유효하지 않아도 저장은 됨)
        let tag = try await sut.execute(name: "Custom", colorToken: "customColor")

        // Then
        XCTAssertEqual(tag.colorToken, "customColor")
        XCTAssertFalse(tag.hasValidColorToken)
    }

    // MARK: - Unique Names (Different Names Should Work)

    func testExecute_SimilarButDifferentNames_Success() async throws {
        // Given
        _ = try await sut.execute(name: "work")

        // When: 비슷하지만 다른 이름들
        let tag2 = try await sut.execute(name: "works")
        let tag3 = try await sut.execute(name: "working")
        let tag4 = try await sut.execute(name: "homework")

        // Then: 모두 성공
        XCTAssertEqual(tag2.name, "works")
        XCTAssertEqual(tag3.name, "working")
        XCTAssertEqual(tag4.name, "homework")
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
