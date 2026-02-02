import SwiftUI
import AppCore

/// 필터 상세 뷰
/// - 필터 정보 + 필터링된 태스크 목록 표시
struct FilterDetailView: View {
    @EnvironmentObject private var appState: AppState
    let savedView: SavedView

    @State private var showingEditFilter = false

    /// 필터링된 태스크 목록
    private var filteredTasks: [Task] {
        appState.filteredTasks(for: savedView)
    }

    var body: some View {
        Group {
            if filteredTasks.isEmpty {
                VStack(spacing: 16) {
                    // 필터 정보 헤더
                    filterInfoHeader
                        .padding()

                    Spacer()

                    EmptyStateView(
                        title: "일치하는 할 일 없음",
                        message: "조건에 맞는 항목이 없습니다"
                    )

                    Spacer()
                }
            } else {
                // viewType에 따른 뷰 분기
                switch savedView.viewType {
                case .list:
                    listView
                case .board:
                    boardView
                case .calendar:
                    calendarView
                }
            }
        }
        .navigationTitle(savedView.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    // 뷰 타입 변경 메뉴
                    viewTypeMenu

                    // 수정 버튼 (커스텀 필터만)
                    if !savedView.isBuiltIn {
                        Button {
                            showingEditFilter = true
                        } label: {
                            Text("수정")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditFilter) {
            FilterCreateView(editingView: savedView)
        }
        .refreshable {
            await appState.loadData()
        }
    }

    // MARK: - View Type Menu

    private var viewTypeMenu: some View {
        Menu {
            ForEach(ProjectViewType.allCases, id: \.self) { viewType in
                Button {
                    changeViewType(to: viewType)
                } label: {
                    Label(viewType.displayNameKR, systemImage: viewType.iconName)
                }
            }
        } label: {
            Image(systemName: savedView.viewType.iconName)
        }
    }

    private func changeViewType(to newViewType: ProjectViewType) {
        // 뷰 타입 변경 시 SavedView 업데이트
        var updatedView = savedView
        updatedView.viewType = newViewType
        Task {
            await appState.saveSavedView(updatedView)
        }
    }

    // MARK: - List View

    private var listView: some View {
        List {
            // 필터 정보 섹션
            Section {
                filterInfoHeader
            }

            // 태스크 목록 섹션
            Section {
                ForEach(filteredTasks) { task in
                    taskRow(for: task)
                }
            } header: {
                Text("\(filteredTasks.count)개 일치")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Board View

    private var boardView: some View {
        VStack(spacing: 0) {
            // 필터 정보 헤더
            filterInfoHeader
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))

            Text("\(filteredTasks.count)개 일치")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))

            // 보드 뷰
            ProjectBoardView(
                tasks: filteredTasks,
                isTaskCompleted: { appState.isTaskCompleted($0) },
                onToggleComplete: { completeTask($0) }
            )
        }
    }

    // MARK: - Calendar View

    private var calendarView: some View {
        VStack(spacing: 0) {
            // 필터 정보 헤더
            filterInfoHeader
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))

            Text("\(filteredTasks.count)개 일치")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))

            // 캘린더 뷰
            ProjectCalendarView(
                tasks: filteredTasks,
                isTaskCompleted: { appState.isTaskCompleted($0) },
                onToggleComplete: { completeTask($0) }
            )
        }
    }

    // MARK: - Filter Info Header

    private var filterInfoHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if savedView.isBuiltIn {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                }
                Text(savedView.name)
                    .font(.headline)
            }

            Text(savedView.definition.summaryKR)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label(savedView.viewType.displayNameKR, systemImage: savedView.viewType.iconName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !savedView.scope.isGlobal {
                    Label("프로젝트 내", systemImage: "folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Task Row

    @ViewBuilder
    private func taskRow(for task: Task) -> some View {
        let isCompleted = appState.isTaskCompleted(task)
        let projectTitle = appState.projects.first { $0.id == task.projectId }?.title ?? ""

        VStack(alignment: .leading, spacing: 4) {
            TaskRowView(
                task: task,
                isCompleted: isCompleted,
                onToggle: {
                    completeTask(task)
                }
            )

            // 프로젝트 표시 (전역 필터일 경우)
            if savedView.scope.isGlobal && !projectTitle.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.caption2)
                    Text(projectTitle)
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
                .padding(.leading, 44) // 체크박스 너비만큼 들여쓰기
            }
        }
    }

    private func completeTask(_ task: Task) {
        Task {
            do {
                try await appState.completeTaskUseCase.execute(
                    taskId: task.id,
                    at: Date()
                )
                await appState.loadData()
            } catch {
                appState.error = error
            }
        }
    }
}

// MARK: - ProjectViewType Extensions

extension ProjectViewType {
    /// FilterDetailView에서 사용하는 표시 이름 (AppCore의 labelKR 활용)
    var displayNameKR: String {
        labelKR
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FilterDetailView(savedView: BuiltInFilters.today)
    }
    .environmentObject(AppState())
}
