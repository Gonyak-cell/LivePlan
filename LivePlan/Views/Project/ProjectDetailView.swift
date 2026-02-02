import SwiftUI
import AppCore

struct ProjectDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let project: Project
    @State private var showingAddTask = false
    @State private var completingTask: Task?
    @State private var selectedViewType: ProjectViewType = .list
    @State private var hasInitializedViewType = false
    @State private var selectedTask: Task?
    @State private var showingSectionManage = false
    @State private var showingProjectNote = false

    var tasks: [Task] {
        appState.tasksForProject(project.id)
    }

    var sections: [Section] {
        appState.sectionsForProject(project.id)
    }

    var incompleteTasks: [Task] {
        tasks.filter { !appState.isTaskCompleted($0) }
    }

    var completedTasks: [Task] {
        tasks.filter { appState.isTaskCompleted($0) }
    }

    /// 섹션별 태스크 그룹핑 (미완료 태스크만)
    /// - M2-11: 섹션별 그룹핑 + 미분류 섹션
    var tasksBySection: [(section: Section?, tasks: [Task])] {
        var result: [(Section?, [Task])] = []

        // 미분류 태스크 (sectionId가 nil인 것)
        let unassigned = incompleteTasks.filter { $0.sectionId == nil }
        if !unassigned.isEmpty {
            result.append((nil, unassigned))
        }

        // 섹션별 태스크
        for section in sections.sorted() {
            let sectionTasks = incompleteTasks.filter { $0.sectionId == section.id }
            if !sectionTasks.isEmpty {
                result.append((section, sectionTasks))
            }
        }

        return result
    }

    var body: some View {
        Group {
            switch selectedViewType {
            case .list:
                listContentView
            case .board:
                ProjectBoardView(
                    tasks: tasks,
                    isTaskCompleted: { appState.isTaskCompleted($0) },
                    onToggleComplete: { toggleComplete($0) }
                )
            case .calendar:
                ProjectCalendarView(
                    tasks: tasks,
                    isTaskCompleted: { appState.isTaskCompleted($0) },
                    onToggleComplete: { toggleComplete($0) }
                )
            }
        }
        .navigationTitle(project.title)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("뷰 타입", selection: $selectedViewType) {
                    ForEach(ProjectViewType.allCases, id: \.self) { viewType in
                        Image(systemName: viewType.iconName)
                            .tag(viewType)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Button {
                        showingProjectNote = true
                    } label: {
                        Label(project.hasNote ? "노트 편집" : "노트 추가", systemImage: "note.text")
                    }

                    Button {
                        showingSectionManage = true
                    } label: {
                        Label("섹션 관리", systemImage: "folder.badge.gearshape")
                    }

                    Divider()

                    if appState.settings.pinnedProjectId != project.id {
                        Button {
                            setPinned()
                        } label: {
                            Label("대표 프로젝트로 설정", systemImage: "pin")
                        }
                    } else {
                        Button {
                            unsetPinned()
                        } label: {
                            Label("대표 프로젝트 해제", systemImage: "pin.slash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            TaskCreateView(projectId: project.id)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
        .sheet(isPresented: $showingSectionManage) {
            SectionManageView(projectId: project.id)
        }
        .sheet(isPresented: $showingProjectNote) {
            ProjectNoteView(project: project)
        }
        .refreshable {
            await appState.loadData()
        }
        .onAppear {
            // M3-05: 첫 로드 시 AppSettings에서 기본 뷰 타입 읽기
            if !hasInitializedViewType {
                selectedViewType = appState.settings.defaultProjectViewType
                hasInitializedViewType = true
            }
        }
        .onChange(of: selectedViewType) { _, newValue in
            // M3-05: 뷰 타입 변경 시 AppSettings에 저장
            if hasInitializedViewType {
                saveDefaultViewType(newValue)
            }
        }
    }

    // MARK: - List Content View

    private var listContentView: some View {
        List {
            // M2-11: 섹션별 그룹핑된 미완료 태스크
            ForEach(tasksBySection, id: \.section?.id) { group in
                Section(sectionHeader(for: group.section)) {
                    ForEach(group.tasks) { task in
                        TaskRowView(
                            task: task,
                            isCompleted: false,
                            tags: appState.tagsForTask(task),
                            onToggle: { toggleComplete(task) }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTask = task
                        }
                    }
                }
            }

            // 완료된 태스크
            if !completedTasks.isEmpty {
                Section("완료") {
                    ForEach(completedTasks) { task in
                        TaskRowView(
                            task: task,
                            isCompleted: true,
                            tags: appState.tagsForTask(task),
                            onToggle: { }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTask = task
                        }
                    }
                }
            }

            // 빈 상태
            if tasks.isEmpty {
                Section {
                    EmptyStateView(
                        title: "할 일이 없습니다",
                        message: "새 할 일을 추가해보세요",
                        actionTitle: "할 일 추가",
                        action: { showingAddTask = true }
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// 섹션 헤더 텍스트
    private func sectionHeader(for section: Section?) -> String {
        section?.title ?? "미분류"
    }

    // MARK: - Actions

    private func toggleComplete(_ task: Task) {
        Task {
            do {
                _ = try await appState.completeTaskUseCase.execute(taskId: task.id)
                await appState.loadData()
            } catch {
                appState.error = error
            }
        }
    }

    private func setPinned() {
        Task {
            var newSettings = appState.settings
            newSettings.pinnedProjectId = project.id
            await appState.saveSettings(newSettings)
        }
    }

    private func unsetPinned() {
        Task {
            var newSettings = appState.settings
            newSettings.pinnedProjectId = nil
            await appState.saveSettings(newSettings)
        }
    }

    /// M3-05: 기본 뷰 타입 저장
    private func saveDefaultViewType(_ viewType: ProjectViewType) {
        Task {
            var newSettings = appState.settings
            newSettings.defaultProjectViewType = viewType
            await appState.saveSettings(newSettings)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProjectDetailView(project: Project(title: "테스트 프로젝트", startDate: Date()))
    }
    .environmentObject(AppState())
}
