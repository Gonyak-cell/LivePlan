import Foundation

/// 섹션 추가 Use Case
/// - data-model.md A2 준수: 섹션은 프로젝트 내부 그룹
/// - architecture.md B3 준수: 도메인 로직은 AppCore에만
public struct AddSectionUseCase: Sendable {
    private let sectionRepository: any SectionRepository
    private let projectRepository: any ProjectRepository

    public init(
        sectionRepository: any SectionRepository,
        projectRepository: any ProjectRepository
    ) {
        self.sectionRepository = sectionRepository
        self.projectRepository = projectRepository
    }

    /// 섹션 추가
    /// - Parameters:
    ///   - title: 섹션 제목
    ///   - projectId: 소속 프로젝트 ID
    ///   - orderIndex: 정렬 순서 (nil이면 자동 계산)
    /// - Returns: 생성된 섹션
    public func execute(
        title: String,
        projectId: String,
        orderIndex: Int? = nil
    ) async throws -> Section {
        // 1. 입력 검증: 제목
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw AddSectionError.emptyTitle
        }

        // 2. 입력 검증: 프로젝트 존재 여부
        guard let project = try await projectRepository.load(id: projectId) else {
            throw AddSectionError.projectNotFound
        }

        // 3. 프로젝트가 활성 상태인지 확인
        guard project.status == .active else {
            throw AddSectionError.projectNotActive
        }

        // 4. orderIndex 계산 (제공되지 않으면 마지막 순서로)
        let resolvedOrderIndex: Int
        if let orderIndex {
            resolvedOrderIndex = orderIndex
        } else {
            resolvedOrderIndex = try await sectionRepository.nextOrderIndex(for: projectId)
        }

        // 5. 섹션 생성
        let section = Section(
            projectId: projectId,
            title: trimmedTitle,
            orderIndex: resolvedOrderIndex
        )

        // 6. 저장
        try await sectionRepository.save(section)

        return section
    }
}

// MARK: - Errors

public enum AddSectionError: Error, LocalizedError, Equatable {
    case emptyTitle
    case projectNotFound
    case projectNotActive

    public var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Section title cannot be empty"
        case .projectNotFound:
            return "Project not found"
        case .projectNotActive:
            return "Cannot add section to archived or completed project"
        }
    }
}
