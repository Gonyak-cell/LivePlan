import Foundation

/// 프로젝트 수정 Use Case
/// - data-model.md A1: Project 엔티티 정의 준수
/// - architecture.md B3: AppCore에서 도메인 판단
public struct UpdateProjectUseCase: Sendable {
    private let projectRepository: any ProjectRepository

    public init(projectRepository: any ProjectRepository) {
        self.projectRepository = projectRepository
    }

    /// 프로젝트 수정
    /// - Parameters:
    ///   - projectId: 수정할 프로젝트 ID
    ///   - title: 새 제목 (nil이면 변경 안 함)
    ///   - startDate: 새 시작일 (nil이면 변경 안 함)
    ///   - dueDate: 새 마감일 (.some(date)면 설정, .some(nil)이면 제거, nil이면 변경 안 함)
    ///   - status: 새 상태 (nil이면 변경 안 함)
    ///   - note: 새 노트 (.some(text)면 설정, .some(nil)이면 제거, nil이면 변경 안 함)
    /// - Returns: 수정된 프로젝트
    public func execute(
        projectId: String,
        title: String? = nil,
        startDate: Date? = nil,
        dueDate: OptionalValue<Date>? = nil,
        status: ProjectStatus? = nil,
        note: OptionalValue<String>? = nil
    ) async throws -> Project {
        // 1. 기존 프로젝트 조회
        guard var project = try await projectRepository.load(id: projectId) else {
            throw UpdateProjectError.projectNotFound(projectId)
        }

        // 2. Inbox 프로젝트는 수정 불가 (시스템 프로젝트)
        if project.isInbox {
            throw UpdateProjectError.cannotModifyInbox
        }

        // 3. 제목 수정
        if let newTitle = title {
            let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else {
                throw UpdateProjectError.emptyTitle
            }
            project.title = trimmedTitle
        }

        // 4. 시작일 수정
        if let newStartDate = startDate {
            project.startDate = newStartDate
        }

        // 5. 마감일 수정
        if let dueDateValue = dueDate {
            project.dueDate = dueDateValue.value
        }

        // 6. 날짜 불변식 검증 (dueDate >= startDate)
        if let due = project.dueDate, due < project.startDate {
            throw UpdateProjectError.invalidDateRange
        }

        // 7. 상태 수정
        if let newStatus = status {
            project.status = newStatus
        }

        // 8. 노트 수정
        if let noteValue = note {
            project.note = noteValue.value
        }

        // 9. updatedAt 갱신
        project.updatedAt = Date()

        // 10. 저장
        try await projectRepository.save(project)

        return project
    }
}

// MARK: - Errors

public enum UpdateProjectError: Error, LocalizedError, Equatable {
    case projectNotFound(String)
    case cannotModifyInbox
    case emptyTitle
    case invalidDateRange

    public var errorDescription: String? {
        switch self {
        case .projectNotFound(let id):
            return "Project not found: \(id)"
        case .cannotModifyInbox:
            return "Cannot modify Inbox project"
        case .emptyTitle:
            return "Project title cannot be empty"
        case .invalidDateRange:
            return "Due date must be on or after start date"
        }
    }
}
