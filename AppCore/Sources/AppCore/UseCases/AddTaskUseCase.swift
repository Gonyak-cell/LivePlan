import Foundation

/// 태스크 추가 Use Case
/// - data-model.md A4 준수: Phase 2 필드 지원
/// - intents.md: QuickAdd 정책 (pinned 우선, 없으면 Inbox)
/// - product-decisions.md 5: QuickAdd 파싱 지원 (parse=true)
public struct AddTaskUseCase: Sendable {
    private let taskRepository: any TaskRepository
    private let projectRepository: any ProjectRepository
    private let sectionRepository: (any SectionRepository)?
    private let tagRepository: (any TagRepository)?

    public init(
        taskRepository: any TaskRepository,
        projectRepository: any ProjectRepository,
        sectionRepository: (any SectionRepository)? = nil,
        tagRepository: (any TagRepository)? = nil
    ) {
        self.taskRepository = taskRepository
        self.projectRepository = projectRepository
        self.sectionRepository = sectionRepository
        self.tagRepository = tagRepository
    }

    /// 태스크 추가
    /// - Parameters:
    ///   - title: 제목 (parse=true면 파싱됨)
    ///   - parse: QuickAdd 파싱 활성화 (기본 false)
    ///   - projectId: 프로젝트 ID (nil이면 기본 프로젝트)
    ///   - taskType: 태스크 유형
    ///   - dueDate: 마감일
    ///   - priority: 우선순위 (기본 P4)
    ///   - tagIds: 태그 ID 목록 (기본 빈 배열)
    ///   - workflowState: 워크플로 상태 (기본 todo)
    ///   - sectionId: 섹션 ID (nil이면 미분류)
    ///   - note: 노트 (선택)
    ///   - pinnedProjectId: 핀 프로젝트 ID (기본 프로젝트 결정용)
    /// - Returns: 생성된 태스크
    public func execute(
        title: String,
        parse: Bool = false,
        projectId: String? = nil,
        taskType: TaskType = .oneOff,
        dueDate: Date? = nil,
        priority: Priority = .defaultPriority,
        tagIds: [String] = [],
        workflowState: WorkflowState = .defaultState,
        sectionId: String? = nil,
        note: String? = nil,
        pinnedProjectId: String? = nil
    ) async throws -> Task {
        // 0. 파싱 적용 (parse=true인 경우)
        var finalTitle = title
        var finalDueDate = dueDate
        var finalPriority = priority
        var finalTagIds = tagIds
        var finalProjectId = projectId
        var finalSectionId = sectionId

        if parse {
            let parser = QuickAddParser()
            let parsed = parser.parse(title)

            finalTitle = parsed.title

            // 파싱된 값 적용 (명시적 값이 없는 경우에만)
            if dueDate == nil {
                finalDueDate = parsed.combinedDueDate()
            }

            if priority == .defaultPriority, let parsedPriority = parsed.priority {
                finalPriority = parsedPriority
            }

            // 태그 이름 → ID 매칭
            if tagIds.isEmpty && !parsed.tagNames.isEmpty {
                finalTagIds = await matchTagNames(parsed.tagNames)
            }

            // 프로젝트 이름 → ID 매칭
            if projectId == nil, let parsedProjectName = parsed.projectName {
                finalProjectId = await matchProjectName(parsedProjectName)
            }

            // 섹션 이름 → ID 매칭
            if sectionId == nil, let parsedSectionName = parsed.sectionName {
                let effectiveProjectId = finalProjectId ?? pinnedProjectId
                finalSectionId = await matchSectionName(parsedSectionName, in: effectiveProjectId)
            }
        }

        // 1. 입력 검증
        let trimmedTitle = finalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw AddTaskError.emptyTitle
        }

        // 2. 프로젝트 결정 (intents.md 정책: pinned 우선, 없으면 Inbox)
        let targetProjectId: String
        if let projectId = finalProjectId {
            // 명시적 지정 (또는 파싱된 프로젝트)
            targetProjectId = projectId
        } else if let pinnedId = pinnedProjectId,
                  let pinnedProject = try await projectRepository.load(id: pinnedId),
                  pinnedProject.status == .active {
            // 핀 프로젝트 사용
            targetProjectId = pinnedId
        } else {
            // Inbox 폴백
            let inbox = try await projectRepository.getOrCreateInbox()
            targetProjectId = inbox.id
        }

        // 3. 프로젝트 존재 확인
        guard try await projectRepository.load(id: targetProjectId) != nil else {
            throw AddTaskError.projectNotFound(targetProjectId)
        }

        // 4. 섹션 검증 (지정된 경우)
        if let sectionId = finalSectionId {
            guard let sectionRepo = sectionRepository else {
                throw AddTaskError.sectionValidationUnavailable
            }
            guard let section = try await sectionRepo.load(id: sectionId) else {
                throw AddTaskError.sectionNotFound(sectionId)
            }
            // 섹션이 동일 프로젝트에 속하는지 확인
            guard section.projectId == targetProjectId else {
                throw AddTaskError.sectionProjectMismatch(sectionId: sectionId, projectId: targetProjectId)
            }
        }

        // 5. 노트 정리 (빈 문자열은 nil로)
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = trimmedNote?.isEmpty == true ? nil : trimmedNote

        // 6. 태스크 생성
        let task = Task(
            projectId: targetProjectId,
            title: trimmedTitle,
            taskType: taskType,
            dueDate: finalDueDate,
            sectionId: finalSectionId,
            tagIds: finalTagIds,
            priority: finalPriority,
            workflowState: workflowState,
            note: finalNote
        )

        // 7. 저장
        try await taskRepository.save(task)

        return task
    }
}

// MARK: - Name to ID Matching

extension AddTaskUseCase {
    /// 태그 이름들 → ID 매칭
    /// - 존재하는 태그만 매칭 (없는 태그는 무시)
    private func matchTagNames(_ names: [String]) async -> [String] {
        guard let tagRepo = tagRepository else { return [] }

        var tagIds: [String] = []
        for name in names {
            if let tag = try? await tagRepo.load(byName: name) {
                tagIds.append(tag.id)
            }
        }
        return tagIds
    }

    /// 프로젝트 이름 → ID 매칭
    /// - 활성 프로젝트만 매칭 (없으면 nil)
    private func matchProjectName(_ name: String) async -> String? {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)
        guard let allProjects = try? await projectRepository.loadAll() else { return nil }

        return allProjects.first {
            $0.title.lowercased().trimmingCharacters(in: .whitespaces) == normalizedName &&
            $0.status == .active
        }?.id
    }

    /// 섹션 이름 → ID 매칭
    /// - 해당 프로젝트 내 섹션만 매칭
    private func matchSectionName(_ name: String, in projectId: String?) async -> String? {
        guard let projectId, let sectionRepo = sectionRepository else { return nil }

        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)
        guard let sections = try? await sectionRepo.loadByProject(projectId: projectId) else { return nil }

        return sections.first {
            $0.title.lowercased().trimmingCharacters(in: .whitespaces) == normalizedName
        }?.id
    }
}

// MARK: - Errors

public enum AddTaskError: Error, LocalizedError, Equatable {
    case emptyTitle
    case projectNotFound(String)
    case sectionNotFound(String)
    case sectionProjectMismatch(sectionId: String, projectId: String)
    case sectionValidationUnavailable

    public var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Task title cannot be empty"
        case .projectNotFound(let id):
            return "Project not found: \(id)"
        case .sectionNotFound(let id):
            return "Section not found: \(id)"
        case .sectionProjectMismatch(let sectionId, let projectId):
            return "Section \(sectionId) does not belong to project \(projectId)"
        case .sectionValidationUnavailable:
            return "Section validation unavailable: SectionRepository not provided"
        }
    }
}
