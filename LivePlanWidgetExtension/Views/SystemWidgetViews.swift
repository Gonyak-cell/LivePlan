import SwiftUI
import WidgetKit
import AppCore

/// 홈화면 작은 위젯
struct SystemSmallView: View {
    let entry: LivePlanEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.blue)
                Text("LivePlan")
                    .font(.caption.bold())
            }

            Spacer()

            // 카운트
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(entry.summary.counters.outstandingTotal)")
                        .font(.largeTitle.bold())
                    Text("미완료")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if entry.summary.counters.overdueCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("\(entry.summary.counters.overdueCount) 지연")
                            .font(.caption)
                    }
                }

                if entry.summary.counters.recurringTotal > 0 {
                    Text("반복 \(entry.summary.counters.recurringDone)/\(entry.summary.counters.recurringTotal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}

/// 홈화면 중간 위젯
struct SystemMediumView: View {
    let entry: LivePlanEntry

    var body: some View {
        HStack(spacing: 16) {
            // 왼쪽: 카운트
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundStyle(.blue)
                    Text("LivePlan")
                        .font(.caption.bold())
                }

                Spacer()

                HStack(alignment: .firstTextBaseline) {
                    Text("\(entry.summary.counters.outstandingTotal)")
                        .font(.largeTitle.bold())
                    Text("미완료")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    if entry.summary.counters.overdueCount > 0 {
                        Label("\(entry.summary.counters.overdueCount)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if entry.summary.counters.dueSoonCount > 0 {
                        Label("\(entry.summary.counters.dueSoonCount)", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 오른쪽: 태스크 목록
            VStack(alignment: .leading, spacing: 4) {
                if entry.summary.displayList.isEmpty {
                    Text("모두 완료!")
                        .font(.headline)
                    Text("오늘 할 일을 마쳤습니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.summary.displayList.prefix(3)) { task in
                        HStack(spacing: 4) {
                            Image(systemName: "circle")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(task.displayTitle)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            if task.isOverdue {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    if entry.summary.counters.outstandingTotal > 3 {
                        Text("+\(entry.summary.counters.outstandingTotal - 3) 더 있음")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    LivePlanWidget()
} timeline: {
    LivePlanEntry(
        date: Date(),
        summary: LockScreenSummary(
            displayList: [DisplayTask(id: "1", displayTitle: "Task")],
            counters: Counters(outstandingTotal: 5, overdueCount: 2, recurringDone: 1, recurringTotal: 3)
        ),
        privacyMode: .masked
    )
}

#Preview("Medium", as: .systemMedium) {
    LivePlanWidget()
} timeline: {
    LivePlanEntry(
        date: Date(),
        summary: LockScreenSummary(
            displayList: [
                DisplayTask(id: "1", displayTitle: "할 일 1", isOverdue: true),
                DisplayTask(id: "2", displayTitle: "할 일 2"),
                DisplayTask(id: "3", displayTitle: "할 일 3")
            ],
            counters: Counters(outstandingTotal: 5, overdueCount: 1, dueSoonCount: 2)
        ),
        privacyMode: .masked
    )
}
