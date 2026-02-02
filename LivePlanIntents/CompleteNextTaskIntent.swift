import AppIntents
import AppCore
import AppStorage

/// 다음 태스크 완료 인텐트
/// - intents.md 준수: displayList[0]과 정합성 필수
@available(iOS 17.0, *)
struct CompleteNextTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Next Task"
    static var description = IntentDescription("다음 할 일을 완료 처리합니다")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "스코프")
    var scope: ScopeEntity

    @Parameter(title: "반복 포함")
    var allowRecurring: Bool

    init() {
        self.scope = .pinned
        self.allowRecurring = true
    }

    init(scope: ScopeEntity, allowRecurring: Bool = true) {
        self.scope = scope
        self.allowRecurring = allowRecurring
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let storage = FileBasedStorage()
        let snapshot = await storage.load()

        // 선정 알고리즘으로 대상 결정
        let computer = OutstandingComputer()
        let policy: SelectionPolicy
        switch scope {
        case .pinned:
            policy = .pinnedFirst(projectId: snapshot.settings.pinnedProjectId)
        case .today:
            policy = .todayOverview
        }

        let summary = computer.compute(
            dateKey: .today(),
            policy: policy,
            privacyMode: snapshot.settings.privacyMode,
            projects: snapshot.projects,
            tasks: snapshot.tasks,
            completionLogs: snapshot.completionLogs,
            topN: 1
        )

        let masker = PrivacyMasker()

        // 완료 대상 확인
        guard let topDisplay = summary.displayList.first,
              let targetTask = snapshot.tasks.first(where: { $0.id == topDisplay.id }) else {
            let message = masker.intentFailureMessage(reason: .noTaskToComplete)
            return .result(value: message)
        }

        // 반복 태스크 필터링
        if !allowRecurring && targetTask.isRecurring {
            let message = masker.intentFailureMessage(reason: .noTaskToComplete)
            return .result(value: message)
        }

        // 완료 처리
        let completionLogRepo = FileCompletionLogRepository(storage: storage)
        let taskRepo = FileTaskRepository(storage: storage)
        let useCase = CompleteTaskUseCase(
            taskRepository: taskRepo,
            completionLogRepository: completionLogRepo
        )

        do {
            _ = try await useCase.execute(taskId: targetTask.id)

            let message = masker.intentSuccessMessage(
                action: .complete,
                taskTitle: targetTask.title,
                privacyMode: snapshot.settings.privacyMode
            )
            return .result(value: message)
        } catch {
            return .result(value: "완료 처리에 실패했습니다")
        }
    }
}

// MARK: - ScopeEntity

@available(iOS 17.0, *)
struct ScopeEntity: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "스코프"

    static var caseDisplayRepresentations: [ScopeEntity: DisplayRepresentation] = [
        .pinned: "대표 프로젝트",
        .today: "오늘 전체"
    ]

    case pinned
    case today
}
