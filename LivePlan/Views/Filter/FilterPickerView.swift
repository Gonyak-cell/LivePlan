import SwiftUI
import AppCore

/// 필터 빠른 선택 시트
struct FilterPickerView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedFilter: SavedView?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // 전체 보기 (필터 해제)
                Section {
                    Button {
                        selectedFilter = nil
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundStyle(.blue)
                            Text("전체 보기")
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedFilter == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                // 기본 필터
                if !appState.builtInFilters.isEmpty {
                    Section("기본 필터") {
                        ForEach(appState.builtInFilters) { filter in
                            filterButton(for: filter)
                        }
                    }
                }

                // 사용자 필터
                if !appState.customFilters.isEmpty {
                    Section("내 필터") {
                        ForEach(appState.customFilters) { filter in
                            filterButton(for: filter)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("필터 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func filterButton(for filter: SavedView) -> some View {
        let taskCount = appState.filteredTasks(for: filter).count

        Button {
            selectedFilter = filter
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(filter.name)
                            .foregroundStyle(.primary)

                        if filter.isBuiltIn {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }

                    Text(filter.definition.summaryKR)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // 태스크 수
                Text("\(taskCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 4)

                // 선택 표시
                if selectedFilter?.id == filter.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FilterPickerView(selectedFilter: .constant(nil))
        .environmentObject(AppState())
}
