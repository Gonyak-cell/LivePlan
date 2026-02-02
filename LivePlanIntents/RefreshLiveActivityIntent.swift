import AppIntents
import AppCore
import AppStorage

/// Live Activity 갱신 인텐트
/// - intents.md 준수: 멱등성 보장, 경량 실행
@available(iOS 17.0, *)
struct RefreshLiveActivityIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Live Activity"
    static var description = IntentDescription("Live Activity를 갱신합니다")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "표시 모드")
    var displayMode: DisplayModeEntity

    init() {
        self.displayMode = .todaySummary
    }

    init(displayMode: DisplayModeEntity) {
        self.displayMode = displayMode
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let storage = FileBasedStorage()
        let snapshot = await storage.load()

        // 선정 알고리즘 실행
        let computer = OutstandingComputer()
        let policy: SelectionPolicy
        if let pinnedId = snapshot.settings.pinnedProjectId {
            policy = .pinnedFirst(projectId: pinnedId)
        } else {
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

        // Activity 상태 생성
        let activityState = ActivityState.from(
            summary: summary,
            displayMode: displayMode.toActivityDisplayMode,
            privacyMode: snapshot.settings.privacyMode
        )

        // TODO: ActivityKit으로 Live Activity 업데이트
        // Activity<LivePlanActivityAttributes>.update(using: activityState)

        let masker = PrivacyMasker()
        let message = masker.intentSuccessMessage(
            action: .refresh,
            taskTitle: nil,
            privacyMode: snapshot.settings.privacyMode
        )

        return .result(value: message)
    }
}

// MARK: - DisplayModeEntity

@available(iOS 17.0, *)
struct DisplayModeEntity: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "표시 모드"

    static var caseDisplayRepresentations: [DisplayModeEntity: DisplayRepresentation] = [
        .pinnedSummary: "대표 프로젝트 요약",
        .todaySummary: "오늘 요약",
        .focusOne: "집중 모드"
    ]

    case pinnedSummary
    case todaySummary
    case focusOne

    var toActivityDisplayMode: ActivityDisplayMode {
        switch self {
        case .pinnedSummary: return .pinnedSummary
        case .todaySummary: return .todaySummary
        case .focusOne: return .focusOne
        }
    }
}
