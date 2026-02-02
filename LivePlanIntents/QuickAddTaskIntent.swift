import AppIntents
import AppCore
import AppStorage

/// 빠른 태스크 추가 인텐트
/// - intents.md 준수: pinned 우선, 없으면 Inbox
/// - Phase 2: priority, projectId 파라미터 추가
@available(iOS 17.0, *)
struct QuickAddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Task"
    static var description = IntentDescription("빠르게 할 일을 추가합니다")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "할 일")
    var text: String

    @Parameter(title: "유형")
    var taskType: TaskTypeEntity

    @Parameter(title: "우선순위")
    var priority: PriorityEntity?

    @Parameter(title: "프로젝트 ID")
    var projectId: String?

    init() {
        self.text = ""
        self.taskType = .oneOff
        self.priority = nil
        self.projectId = nil
    }

    init(
        text: String,
        taskType: TaskTypeEntity = .oneOff,
        priority: PriorityEntity? = nil,
        projectId: String? = nil
    ) {
        self.text = text
        self.taskType = taskType
        self.priority = priority
        self.projectId = projectId
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let storage = FileBasedStorage()
        let snapshot = await storage.load()

        let masker = PrivacyMasker()

        // 입력 검증
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            let message = masker.intentFailureMessage(reason: .emptyInput)
            return .result(value: message)
        }

        // Repository 생성
        let taskRepo = FileTaskRepository(storage: storage)
        let projectRepo = FileProjectRepository(storage: storage)

        // Use case 실행
        let useCase = AddTaskUseCase(
            taskRepository: taskRepo,
            projectRepository: projectRepo
        )

        do {
            let task = try await useCase.execute(
                title: trimmedText,
                projectId: projectId, // 지정하면 해당 프로젝트, 아니면 자동 결정
                taskType: taskType.toTaskType,
                dueDate: nil,
                priority: priority?.toPriority ?? .defaultPriority,
                pinnedProjectId: snapshot.settings.pinnedProjectId
            )

            let message = masker.intentSuccessMessage(
                action: .add,
                taskTitle: task.title,
                privacyMode: snapshot.settings.privacyMode
            )
            return .result(value: message)
        } catch {
            return .result(value: "추가에 실패했습니다")
        }
    }
}

// MARK: - TaskTypeEntity

@available(iOS 17.0, *)
struct TaskTypeEntity: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "유형"

    static var caseDisplayRepresentations: [TaskTypeEntity: DisplayRepresentation] = [
        .oneOff: "일반",
        .dailyRecurring: "매일 반복"
    ]

    case oneOff
    case dailyRecurring

    var toTaskType: TaskType {
        switch self {
        case .oneOff: return .oneOff
        case .dailyRecurring: return .dailyRecurring
        }
    }
}
