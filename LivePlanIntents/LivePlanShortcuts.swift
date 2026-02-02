import AppIntents

/// LivePlan App Shortcuts
@available(iOS 17.0, *)
struct LivePlanShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompleteNextTaskIntent(),
            phrases: [
                "다음 할 일 완료 \(.applicationName)",
                "할 일 완료 \(.applicationName)",
                "Complete next task in \(.applicationName)"
            ],
            shortTitle: "할 일 완료",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: QuickAddTaskIntent(),
            phrases: [
                "할 일 추가 \(.applicationName)",
                "빠른 추가 \(.applicationName)",
                "Add task to \(.applicationName)"
            ],
            shortTitle: "빠른 추가",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: RefreshLiveActivityIntent(),
            phrases: [
                "Live Activity 갱신 \(.applicationName)",
                "활동 갱신 \(.applicationName)",
                "Refresh \(.applicationName)"
            ],
            shortTitle: "활동 갱신",
            systemImageName: "arrow.clockwise"
        )
    }
}
