import Foundation

/// 태그 추가 Use Case
/// - data-model.md A3 준수: 태그의 다대다 분류
/// - architecture.md B3 준수: 도메인 로직은 AppCore에만
public struct AddTagUseCase: Sendable {
    private let tagRepository: any TagRepository

    public init(tagRepository: any TagRepository) {
        self.tagRepository = tagRepository
    }

    /// 태그 추가
    /// - Parameters:
    ///   - name: 태그 이름 (필수)
    ///   - colorToken: 색상 토큰 (선택)
    /// - Returns: 생성된 태그
    /// - Throws: AddTagError
    public func execute(
        name: String,
        colorToken: String? = nil
    ) async throws -> Tag {
        // 1. 입력 검증: 이름
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw AddTagError.emptyName
        }

        // 2. 중복 검사 (대소문자 무시)
        // data-model.md: name은 대소문자 무시 유니크 권장
        if let existing = try await tagRepository.load(byName: trimmedName) {
            throw AddTagError.duplicateName(existingTag: existing)
        }

        // 3. 태그 생성
        let tag = Tag(
            name: trimmedName,
            colorToken: colorToken
        )

        // 4. 저장
        try await tagRepository.save(tag)

        return tag
    }
}

// MARK: - Errors

public enum AddTagError: Error, LocalizedError, Equatable {
    case emptyName
    case duplicateName(existingTag: Tag)

    public var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Tag name cannot be empty"
        case .duplicateName(let existingTag):
            return "Tag '\(existingTag.name)' already exists"
        }
    }
}
