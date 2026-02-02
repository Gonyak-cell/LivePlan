import SwiftUI
import WidgetKit
import AppCore

/// 잠금화면 직사각 위젯
/// - lockscreen.md A 준수: Top 3 + 카운트
struct LockScreenRectangularView: View {
    let entry: LivePlanEntry

    var body: some View {
        if entry.summary.displayList.isEmpty {
            emptyView
        } else {
            contentView
        }
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("LivePlan")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)

            Text("모두 완료!")
                .font(.headline)

            if entry.summary.counters.recurringTotal > 0 {
                Text("반복: \(entry.summary.counters.recurringDone)/\(entry.summary.counters.recurringTotal)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 헤더
            HStack {
                Text("LivePlan")
                    .font(.caption2.bold())

                Spacer()

                // 카운트
                HStack(spacing: 4) {
                    if entry.summary.counters.overdueCount > 0 {
                        Text("지연 \(entry.summary.counters.overdueCount)")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }

                    Text("미완료 \(entry.summary.counters.outstandingTotal)")
                        .font(.caption2)
                }
            }
            .foregroundStyle(.secondary)

            // Top 3 태스크
            ForEach(entry.summary.displayList.prefix(3)) { task in
                HStack(spacing: 4) {
                    Image(systemName: "circle")
                        .font(.caption2)

                    Text(task.displayTitle)
                        .font(.caption)
                        .lineLimit(1)

                    if task.isOverdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }

                    if task.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }

            // 추가 항목 표시
            if entry.summary.counters.outstandingTotal > 3 {
                Text("+\(entry.summary.counters.outstandingTotal - 3) 더 있음")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("With Tasks", as: .accessoryRectangular) {
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
            counters: Counters(outstandingTotal: 5, overdueCount: 1)
        ),
        privacyMode: .masked
    )
}

#Preview("Empty", as: .accessoryRectangular) {
    LivePlanWidget()
} timeline: {
    LivePlanEntry(
        date: Date(),
        summary: .empty,
        privacyMode: .masked
    )
}
