import Foundation

/// 프로젝트 추가 Use Case
public struct AddProjectUseCase: Sendable {
    private let projectRepository: any ProjectRepository

    public init(projectRepository: any ProjectRepository) {
        self.projectRepository = projectRepository
    }

    /// 프로젝트 추가
    /// - Parameters:
    ///   - title: 제목
    ///   - startDate: 시작일
    ///   - dueDate: 마감일 (선택)
    /// - Returns: 생성된 프로젝트
    public func execute(
        title: String,
        startDate: Date,
        dueDate: Date? = nil
    ) async throws -> Project {
        // 1. 입력 검증
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw AddProjectError.emptyTitle
        }

        // 2. 날짜 검증 (dueDate >= startDate)
        if let dueDate, dueDate < startDate {
            throw AddProjectError.invalidDateRange
        }

        // 3. 프로젝트 생성
        let project = Project(
            title: trimmedTitle,
            startDate: startDate,
            dueDate: dueDate
        )

        // 4. 저장
        try await projectRepository.save(project)

        return project
    }
}

// MARK: - Errors

public enum AddProjectError: Error, LocalizedError {
    case emptyTitle
    case invalidDateRange

    public var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Project title cannot be empty"
        case .invalidDateRange:
            return "Due date must be on or after start date"
        }
    }
}
