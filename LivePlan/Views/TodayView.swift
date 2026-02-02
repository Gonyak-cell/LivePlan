import SwiftUI
import AppCore

/// 오늘 뷰 - 잠금화면과 동일한 선정 알고리즘 사용
struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedFilter: SavedView?
    @State private var showingFilterPicker = false

    var summary: LockScreenSummary {
        appState.lockScreenSummary(topN: 10)
    }

    /// 필터가 선택된 경우 필터링된 태스크, 아니면 기본 summary 태스크
    private var displayTasks: [Task] {
        if let filter = selectedFilter {
            return appState.filteredTasks(for: filter)
        } else {
            return summary.displayList.compactMap { display in
                appState.tasks.first { $0.id == display.id }
            }
        }
    }

    /// 필터 적용 중인지 여부
    private var isFilterActive: Bool {
        selectedFilter != nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if !isFilterActive && summary.counters.outstandingTotal == 0 {
                    allDoneView
                } else if displayTasks.isEmpty {
                    filterEmptyView
                } else {
                    taskListView
                }
            }
            .navigationTitle(isFilterActive ? (selectedFilter?.name ?? "필터") : "오늘")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFilterPicker = true
                    } label: {
                        Image(systemName: isFilterActive
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await appState.loadData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingFilterPicker) {
                FilterPickerView(selectedFilter: $selectedFilter)
            }
            .refreshable {
                await appState.loadData()
            }
        }
    }

    private var filterEmptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("일치하는 할 일 없음")
                .font(.headline)

            if let filter = selectedFilter {
                Text(filter.definition.summaryKR)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("필터 해제") {
                selectedFilter = nil
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var allDoneView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("모두 완료했습니다!")
                .font(.title2.bold())

            Text("오늘 할 일을 모두 마쳤습니다")
                .foregroundStyle(.secondary)

            if summary.counters.recurringTotal > 0 {
                Text("반복: \(summary.counters.recurringDone)/\(summary.counters.recurringTotal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var taskListView: some View {
        List {
            // 요약 헤더 (필터 미적용 시에만)
            if !isFilterActive {
                Section {
                    SummaryHeaderView(counters: summary.counters)
                }
            }

            // 필터 적용 시 필터 정보 표시
            if isFilterActive, let filter = selectedFilter {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(filter.name)
                                .font(.subheadline.bold())
                            Text(filter.definition.summaryKR)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("해제") {
                            selectedFilter = nil
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
            }

            // 태스크 목록
            Section(isFilterActive ? "\(displayTasks.count)개 일치" : "미완료 (\(summary.counters.outstandingTotal))") {
                ForEach(displayTasks) { task in
                    TaskRowView(
                        task: task,
                        isCompleted: appState.isTaskCompleted(task),
                        onToggle: { completeTask(task) }
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func completeTask(_ task: Task) {
        Task {
            do {
                _ = try await appState.completeTaskUseCase.execute(taskId: task.id)
                await appState.loadData()
            } catch {
                appState.error = error
            }
        }
    }
}

// MARK: - SummaryHeaderView

struct SummaryHeaderView: View {
    let counters: Counters

    var body: some View {
        HStack(spacing: 16) {
            CounterBadge(
                title: "미완료",
                count: counters.outstandingTotal,
                color: .blue
            )

            if counters.overdueCount > 0 {
                CounterBadge(
                    title: "지연",
                    count: counters.overdueCount,
                    color: .red
                )
            }

            if counters.dueSoonCount > 0 {
                CounterBadge(
                    title: "임박",
                    count: counters.dueSoonCount,
                    color: .orange
                )
            }

            if counters.recurringTotal > 0 {
                CounterBadge(
                    title: "반복",
                    count: counters.recurringDone,
                    total: counters.recurringTotal,
                    color: .purple
                )
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - CounterBadge

struct CounterBadge: View {
    let title: String
    let count: Int
    var total: Int? = nil
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            if let total {
                Text("\(count)/\(total)")
                    .font(.headline.bold())
            } else {
                Text("\(count)")
                    .font(.headline.bold())
            }

            Text(title)
                .font(.caption2)
        }
        .foregroundStyle(color)
        .frame(minWidth: 50)
    }
}

// MARK: - Preview

#Preview {
    TodayView()
        .environmentObject(AppState())
}
