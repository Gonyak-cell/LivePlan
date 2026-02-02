import SwiftUI
import AppCore

/// 필터 목록 뷰
struct FilterListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingCreateFilter = false

    var body: some View {
        NavigationStack {
            Group {
                if appState.savedViews.isEmpty {
                    EmptyStateView(
                        title: "필터가 없습니다",
                        message: "필터를 만들어 자주 쓰는 조건을 저장하세요",
                        actionTitle: "필터 만들기",
                        action: { showingCreateFilter = true }
                    )
                } else {
                    List {
                        // 기본 필터 섹션
                        if !appState.builtInFilters.isEmpty {
                            Section("기본 필터") {
                                ForEach(appState.builtInFilters) { savedView in
                                    NavigationLink {
                                        FilterDetailView(savedView: savedView)
                                    } label: {
                                        FilterRowView(savedView: savedView)
                                    }
                                }
                            }
                        }

                        // 사용자 정의 필터 섹션
                        Section {
                            if appState.customFilters.isEmpty {
                                Text("사용자 필터가 없습니다")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            } else {
                                ForEach(appState.customFilters) { savedView in
                                    NavigationLink {
                                        FilterDetailView(savedView: savedView)
                                    } label: {
                                        FilterRowView(savedView: savedView)
                                    }
                                }
                                .onDelete(perform: deleteCustomFilters)
                            }
                        } header: {
                            Text("내 필터")
                        } footer: {
                            if appState.customFilters.isEmpty {
                                Text("자주 쓰는 조건을 저장하세요")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("필터")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateFilter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateFilter) {
                FilterCreateView()
            }
            .refreshable {
                await appState.loadData()
            }
        }
    }

    private func deleteCustomFilters(at offsets: IndexSet) {
        let filtersToDelete = offsets.map { appState.customFilters[$0] }
        for filter in filtersToDelete {
            Task {
                await appState.deleteSavedView(id: filter.id)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FilterListView()
        .environmentObject(AppState())
}
