import SwiftUI
import WidgetKit
import AppCore

/// 잠금화면 원형 위젯
struct LockScreenCircularView: View {
    let entry: LivePlanEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: "checklist")
                    .font(.title3)

                Text("\(entry.summary.counters.outstandingTotal)")
                    .font(.headline.bold())
            }
        }
    }
}

// MARK: - Preview

#Preview("Circular", as: .accessoryCircular) {
    LivePlanWidget()
} timeline: {
    LivePlanEntry(
        date: Date(),
        summary: LockScreenSummary(
            displayList: [],
            counters: Counters(outstandingTotal: 5)
        ),
        privacyMode: .masked
    )
}
