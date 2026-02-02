import SwiftUI
import AppCore

struct ProjectListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingCreateProject = false

    var body: some View {
        NavigationStack {
            Group {
                if appState.activeProjects.isEmpty {
                    EmptyStateView(
                        title: "프로젝트가 없습니다",
                        message: "새 프로젝트를 만들어 시작하세요",
                        actionTitle: "프로젝트 만들기",
                        action: { showingCreateProject = true }
                    )
                } else {
                    List {
                        // 핀 프로젝트
                        if let pinned = appState.pinnedProject {
                            Section("대표 프로젝트") {
                                ProjectRowView(project: pinned, isPinned: true)
                            }
                        }

                        // 다른 프로젝트
                        Section("프로젝트") {
                            ForEach(appState.activeProjects.filter { $0.id != appState.settings.pinnedProjectId }) { project in
                                ProjectRowView(project: project, isPinned: false)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("프로젝트")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateProject) {
                ProjectCreateView()
            }
            .refreshable {
                await appState.loadData()
            }
        }
    }
}

// MARK: - ProjectRowView

struct ProjectRowView: View {
    @EnvironmentObject private var appState: AppState
    let project: Project
    let isPinned: Bool

    var taskCount: Int {
        appState.tasksForProject(project.id).count
    }

    var outstandingCount: Int {
        let tasks = appState.tasksForProject(project.id)
        return tasks.filter { !appState.isTaskCompleted($0) }.count
    }

    var body: some View {
        NavigationLink {
            ProjectDetailView(project: project)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.title)
                            .font(.headline)

                        if isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    if let dueDate = project.dueDate {
                        Text("마감: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // 카운트 배지
                if outstandingCount > 0 {
                    Text("\(outstandingCount)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue, in: Capsule())
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProjectListView()
        .environmentObject(AppState())
}
