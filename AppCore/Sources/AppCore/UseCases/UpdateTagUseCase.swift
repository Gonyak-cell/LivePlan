import Foundation

/// 태그 수정 Use Case
/// - data-model.md A3 준수: 태그의 다대다 분류
/// - architecture.md B3 준수: 도메인 로직은 AppCore에만
public struct UpdateTagUseCase: Sendable {
    private let tagRepository: any TagRepository

    public init(tagRepository: any TagRepository) {
        self.tagRepository = tagRepository
    }

    /// 태그 수정
    /// - Parameters:
    ///   - tagId: 수정할 태그 ID
    ///   - name: 새 이름 (nil이면 변경 안 함)
    ///   - colorToken: 새 색상 토큰 (nil이면 변경 안 함, .some(nil)이면 색상 제거)
    /// - Returns: 수정된 태그
    /// - Throws: UpdateTagError
    public func execute(
        tagId: String,
        name: String? = nil,
        colorToken: String?? = nil
    ) async throws -> Tag {
        // 1. 태그 조회
        guard var tag = try await tagRepository.load(id: tagId) else {
            throw UpdateTagError.tagNotFound(tagId)
        }

        // 2. 이름 변경 처리
        if let newName = name {
            let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                throw UpdateTagError.emptyName
            }

            // 대소문자 무시 중복 검사 (자기 자신 제외)
            if let existing = try await tagRepository.load(byName: trimmedName),
               existing.id != tagId {
                throw UpdateTagError.duplicateName(existingTag: existing)
            }

            tag.name = trimmedName
        }

        // 3. 색상 토큰 변경 처리
        if let newColorToken = colorToken {
            tag.colorToken = newColorToken
        }

        // 4. updatedAt 갱신
        tag.updatedAt = Date()

        // 5. 저장
        try await tagRepository.save(tag)

        return tag
    }
}

// MARK: - Errors

public enum UpdateTagError: Error, LocalizedError, Equatable {
    case tagNotFound(String)
    case emptyName
    case duplicateName(existingTag: Tag)

    public var errorDescription: String? {
        switch self {
        case .tagNotFound(let id):
            return "Tag not found: \(id)"
        case .emptyName:
            return "Tag name cannot be empty"
        case .duplicateName(let existingTag):
            return "Tag '\(existingTag.name)' already exists"
        }
    }
}
