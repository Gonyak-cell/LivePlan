import Foundation

/// 태그 삭제 Use Case
/// - data-model.md A3 준수: 태그 삭제 시 태스크의 tagIds에서 제거
/// - architecture.md B3 준수: 도메인 로직은 AppCore에만
public struct DeleteTagUseCase: Sendable {
    private let tagRepository: any TagRepository

    public init(tagRepository: any TagRepository) {
        self.tagRepository = tagRepository
    }

    /// 태그 삭제
    /// - Parameter tagId: 삭제할 태그 ID
    /// - Note: 태스크의 tagIds 정리는 저장소 레이어에서 처리됨
    /// - Throws: DeleteTagError
    public func execute(tagId: String) async throws {
        // 1. 태그 존재 확인
        guard try await tagRepository.load(id: tagId) != nil else {
            throw DeleteTagError.tagNotFound(tagId)
        }

        // 2. 삭제 (저장소에서 Task.tagIds 정리 처리)
        try await tagRepository.delete(id: tagId)
    }
}

// MARK: - Errors

public enum DeleteTagError: Error, LocalizedError, Equatable {
    case tagNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .tagNotFound(let id):
            return "Tag not found: \(id)"
        }
    }
}
