import AppIntents
import AppCore
import AppStorage

/// 다음 태스크 시작 인텐트
/// - intents.md 준수: displayList[0]를 workflowState=doing으로 설정
/// - 멱등성: 이미 doing이면 noop
@available(iOS 17.0, *)
struct StartNextTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Next Task"
    static var description = IntentDescription("다음 할 일을 시작합니다")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "스코프")
    var scope: ScopeEntity

    init() {
        self.scope = .pinned
    }

    init(scope: ScopeEntity) {
        self.scope = scope
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

        // 시작 대상 확인
        guard let topDisplay = summary.displayList.first,
              let targetTask = snapshot.tasks.first(where: { $0.id == topDisplay.id }) else {
            let message = masker.intentFailureMessage(reason: .noTaskToStart)
            return .result(value: message)
        }

        // 시작 처리
        let taskRepo = FileTaskRepository(storage: storage)
        let useCase = StartTaskUseCase(taskRepository: taskRepo)

        do {
            _ = try await useCase.execute(taskId: targetTask.id)

            let message = masker.intentSuccessMessage(
                action: .start,
                taskTitle: targetTask.title,
                privacyMode: snapshot.settings.privacyMode
            )
            return .result(value: message)
        } catch {
            return .result(value: "시작 처리에 실패했습니다")
        }
    }
}
