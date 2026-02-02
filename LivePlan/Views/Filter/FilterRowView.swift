import SwiftUI
import AppCore

/// 필터 목록 행 컴포넌트
struct FilterRowView: View {
    @EnvironmentObject private var appState: AppState
    let savedView: SavedView

    /// 필터링된 태스크 수
    var taskCount: Int {
        appState.filteredTasks(for: savedView).count
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(savedView.name)
                        .font(.headline)

                    if savedView.isBuiltIn {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Text(savedView.definition.summaryKR)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 태스크 수 배지
            if taskCount > 0 {
                Text("\(taskCount)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue, in: Capsule())
            } else {
                Text("0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    List {
        FilterRowView(savedView: BuiltInFilters.today)
        FilterRowView(savedView: BuiltInFilters.upcoming)
        FilterRowView(savedView: .custom(
            name: "내 필터",
            definition: FilterDefinition(priorityAtLeast: .p1)
        ))
    }
    .environmentObject(AppState())
}
