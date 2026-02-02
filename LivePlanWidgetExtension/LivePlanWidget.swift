import WidgetKit
import SwiftUI
import AppCore
import AppStorage

// MARK: - Widget Entry

struct LivePlanEntry: TimelineEntry {
    let date: Date
    let summary: LockScreenSummary
    let privacyMode: PrivacyMode
}

// MARK: - Timeline Provider

struct LivePlanProvider: TimelineProvider {
    private let storage = FileBasedStorage()
    private let computer = OutstandingComputer()

    func placeholder(in context: Context) -> LivePlanEntry {
        LivePlanEntry(
            date: Date(),
            summary: .empty,
            privacyMode: .masked
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LivePlanEntry) -> Void) {
        Task {
            let entry = await createEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LivePlanEntry>) -> Void) {
        Task {
            let entry = await createEntry()

            // 다음 갱신: 15분 후 (WidgetKit 제약)
            let nextUpdate = Calendar.current.date(
                byAdding: .minute,
                value: 15,
                to: Date()
            ) ?? Date().addingTimeInterval(900)

            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func createEntry() async -> LivePlanEntry {
        let snapshot = await storage.load()

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
            topN: SelectionConstants.widgetTopN
        )

        return LivePlanEntry(
            date: Date(),
            summary: summary,
            privacyMode: snapshot.settings.privacyMode
        )
    }
}

// MARK: - Widget Bundle

@main
struct LivePlanWidgetBundle: WidgetBundle {
    var body: some Widget {
        LivePlanWidget()
    }
}

// MARK: - Widget Definition

struct LivePlanWidget: Widget {
    let kind: String = "LivePlanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LivePlanProvider()) { entry in
            LivePlanWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("LivePlan")
        .description("오늘 할 일을 확인하세요")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
            .systemSmall,
            .systemMedium
        ])
    }
}

// MARK: - Widget Entry View

struct LivePlanWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LivePlanEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
        case .accessoryInline:
            LockScreenInlineView(entry: entry)
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
        case .systemSmall:
            SystemSmallView(entry: entry)
        case .systemMedium:
            SystemMediumView(entry: entry)
        default:
            LockScreenRectangularView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview("Rectangular", as: .accessoryRectangular) {
    LivePlanWidget()
} timeline: {
    LivePlanEntry(
        date: Date(),
        summary: LockScreenSummary(
            displayList: [
                DisplayTask(id: "1", displayTitle: "할 일 1", isOverdue: true),
                DisplayTask(id: "2", displayTitle: "할 일 2"),
                DisplayTask(id: "3", displayTitle: "할 일 3", isRecurring: true)
            ],
            counters: Counters(outstandingTotal: 5, overdueCount: 1, recurringDone: 2, recurringTotal: 3)
        ),
        privacyMode: .masked
    )
}
