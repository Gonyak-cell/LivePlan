import SwiftUI
import WidgetKit
import AppCore

/// 잠금화면 인라인 위젯
/// - strings-localization.md 길이 예산 준수: 18자 내
struct LockScreenInlineView: View {
    let entry: LivePlanEntry

    var body: some View {
        if entry.summary.displayList.isEmpty {
            Text("모두 완료!")
        } else {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")

                Text(inlineText)
            }
        }
    }

    private var inlineText: String {
        let count = entry.summary.counters.outstandingTotal
        let overdueCount = entry.summary.counters.overdueCount

        if overdueCount > 0 {
            return "미완료 \(count) · 지연 \(overdueCount)"
        }
        return "미완료 \(count)"
    }
}

// MARK: - Preview

#Preview("Inline", as: .accessoryInline) {
    LivePlanWidget()
} timeline: {
    LivePlanEntry(
        date: Date(),
        summary: LockScreenSummary(
            displayList: [DisplayTask(id: "1", displayTitle: "Task")],
            counters: Counters(outstandingTotal: 3, overdueCount: 1)
        ),
        privacyMode: .masked
    )
}
