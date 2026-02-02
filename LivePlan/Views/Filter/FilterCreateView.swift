import SwiftUI
import AppCore

/// 필터 생성/수정 뷰
struct FilterCreateView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    /// 수정 모드인 경우 기존 SavedView
    var editingView: SavedView?

    @State private var name: String = ""
    @State private var scope: ViewScope = .global
    @State private var viewType: ProjectViewType = .list
    @State private var definition: FilterDefinition = .empty

    @State private var showingScopeProjectPicker = false
    @State private var selectedScopeProjectId: String?

    private var isEditing: Bool {
        editingView != nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // 이름 섹션
                Section("이름") {
                    TextField("필터 이름 입력", text: $name)
                }

                // 범위 섹션
                Section("범위") {
                    // 전역 범위 선택
                    Button {
                        scope = .global
                        selectedScopeProjectId = nil
                    } label: {
                        HStack {
                            Text("전체")
                                .foregroundStyle(.primary)
                            Spacer()
                            if scope.isGlobal {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    // 프로젝트 범위 선택
                    Button {
                        if !appState.activeProjects.isEmpty {
                            // 프로젝트가 있으면 첫 번째 프로젝트를 자동 선택
                            if selectedScopeProjectId == nil {
                                let firstProject = appState.activeProjects[0]
                                selectedScopeProjectId = firstProject.id
                                scope = .project(firstProject.id)
                            }
                            showingScopeProjectPicker = true
                        }
                    } label: {
                        HStack {
                            Text("프로젝트 내")
                                .foregroundStyle(.primary)
                            Spacer()
                            if let projectId = selectedScopeProjectId,
                               let project = appState.projects.first(where: { $0.id == projectId }) {
                                Text(project.title)
                                    .foregroundStyle(.secondary)
                            } else if appState.activeProjects.isEmpty {
                                Text("프로젝트 없음")
                                    .foregroundStyle(.secondary)
                            }
                            if !scope.isGlobal {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .disabled(appState.activeProjects.isEmpty)
                    .navigationDestination(isPresented: $showingScopeProjectPicker) {
                        ScopeProjectPickerView(
                            selectedProjectId: $selectedScopeProjectId,
                            onSelect: { projectId in
                                scope = .project(projectId)
                            }
                        )
                    }
                }

                // 보기 형식 섹션
                Section("보기 형식") {
                    Picker("보기 형식", selection: $viewType) {
                        Text("리스트").tag(ProjectViewType.list)
                        Text("보드").tag(ProjectViewType.board)
                        Text("캘린더").tag(ProjectViewType.calendar)
                    }
                    .pickerStyle(.segmented)
                }

                // 조건 섹션
                Section {
                    NavigationLink {
                        FilterBuilderView(definition: $definition)
                    } label: {
                        HStack {
                            Text("조건")
                            Spacer()
                            Text(definition.summaryKR)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                } header: {
                    Text("조건")
                } footer: {
                    Text("여러 조건은 AND로 결합됩니다")
                }

                // 미리보기 섹션
                Section {
                    let filteredCount = appState.applyFilter(definition).count
                    HStack {
                        Text("일치하는 태스크")
                        Spacer()
                        Text("\(filteredCount)개")
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("미리보기")
                }
            }
            .navigationTitle(isEditing ? "필터 수정" : "새 필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("저장") {
                        saveFilter()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let editingView {
                    loadFromSavedView(editingView)
                }
            }
        }
    }

    private func loadFromSavedView(_ savedView: SavedView) {
        name = savedView.name
        scope = savedView.scope
        viewType = savedView.viewType
        definition = savedView.definition

        if case .project(let projectId) = savedView.scope {
            selectedScopeProjectId = projectId
        }
    }

    private func saveFilter() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let savedView: SavedView
        if let editingView {
            // 수정 모드
            savedView = SavedView(
                id: editingView.id,
                name: trimmedName,
                scope: scope,
                viewType: viewType,
                definition: definition,
                createdAt: editingView.createdAt,
                updatedAt: Date(),
                isBuiltIn: false,
                sortOrder: editingView.sortOrder
            )
        } else {
            // 생성 모드
            savedView = SavedView.custom(
                name: trimmedName,
                definition: definition,
                scope: scope,
                viewType: viewType
            )
        }

        Task {
            await appState.saveSavedView(savedView)
            dismiss()
        }
    }
}

// MARK: - Scope Project Picker

struct ScopeProjectPickerView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedProjectId: String?
    var onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(appState.activeProjects) { project in
                Button {
                    selectedProjectId = project.id
                    onSelect(project.id)
                    dismiss()
                } label: {
                    HStack {
                        Text(project.title)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedProjectId == project.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("프로젝트 선택")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Create") {
    FilterCreateView()
        .environmentObject(AppState())
}

#Preview("Edit") {
    FilterCreateView(editingView: BuiltInFilters.today)
        .environmentObject(AppState())
}
