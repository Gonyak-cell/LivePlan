import SwiftUI
import AppCore
import AppStorage

@main
struct LivePlanApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - AppState

/// 앱 전역 상태
@MainActor
final class AppState: ObservableObject {
    // Storage
    let storage: FileBasedStorage
    let projectRepository: FileProjectRepository
    let taskRepository: FileTaskRepository
    let completionLogRepository: FileCompletionLogRepository
    let savedViewRepository: FileSavedViewRepository
    let settingsRepository: FileSettingsRepository
    let sectionRepository: FileSectionRepository
    let tagRepository: FileTagRepository

    // Use Cases
    let addProjectUseCase: AddProjectUseCase
    let updateProjectUseCase: UpdateProjectUseCase
    let addTaskUseCase: AddTaskUseCase
    let completeTaskUseCase: CompleteTaskUseCase
    let applyFilterUseCase: ApplyFilterUseCase
    let updateSettingsUseCase: UpdateSettingsUseCase
    let updateTaskUseCase: UpdateTaskUseCase
    let startTaskUseCase: StartTaskUseCase
    let addTagUseCase: AddTagUseCase
    let updateTagUseCase: UpdateTagUseCase
    let deleteTagUseCase: DeleteTagUseCase
    let addSectionUseCase: AddSectionUseCase

    // Selection
    let outstandingComputer: OutstandingComputer

    // State
    @Published var projects: [Project] = []
    @Published var tasks: [Task] = []
    @Published var completionLogs: [CompletionLog] = []
    @Published var savedViews: [SavedView] = []
    @Published var tags: [Tag] = []
    @Published var sections: [Section] = []
    @Published var settings: AppSettings = .default
    @Published var isLoading = true
    @Published var error: Error?

    init() {
        // Initialize storage
        storage = FileBasedStorage()
        projectRepository = FileProjectRepository(storage: storage)
        taskRepository = FileTaskRepository(storage: storage)
        completionLogRepository = FileCompletionLogRepository(storage: storage)
        savedViewRepository = FileSavedViewRepository(storage: storage)
        settingsRepository = FileSettingsRepository(storage: storage)
        sectionRepository = FileSectionRepository(storage: storage)
        tagRepository = FileTagRepository(storage: storage)

        // Initialize use cases
        addProjectUseCase = AddProjectUseCase(projectRepository: projectRepository)
        updateProjectUseCase = UpdateProjectUseCase(projectRepository: projectRepository)
        addTaskUseCase = AddTaskUseCase(
            taskRepository: taskRepository,
            projectRepository: projectRepository
        )
        completeTaskUseCase = CompleteTaskUseCase(
            taskRepository: taskRepository,
            completionLogRepository: completionLogRepository
        )
        applyFilterUseCase = ApplyFilterUseCase()
        updateSettingsUseCase = UpdateSettingsUseCase(settingsRepository: settingsRepository)
        updateTaskUseCase = UpdateTaskUseCase(
            taskRepository: taskRepository,
            projectRepository: projectRepository
        )
        startTaskUseCase = StartTaskUseCase(taskRepository: taskRepository)
        addTagUseCase = AddTagUseCase(tagRepository: tagRepository)
        updateTagUseCase = UpdateTagUseCase(tagRepository: tagRepository)
        deleteTagUseCase = DeleteTagUseCase(tagRepository: tagRepository)
        addSectionUseCase = AddSectionUseCase(
            sectionRepository: sectionRepository,
            projectRepository: projectRepository
        )

        // Initialize selection
        outstandingComputer = OutstandingComputer()

        // Load initial data
        Task {
            await loadData()
        }
    }

    func loadData() async {
        isLoading = true
        error = nil

        let snapshot = await storage.load()
        projects = snapshot.projects
        tasks = snapshot.tasks
        completionLogs = snapshot.completionLogs
        savedViews = snapshot.savedViews
        tags = snapshot.tags
        sections = snapshot.sections
        settings = snapshot.settings

        // Ensure built-in filters exist
        await ensureBuiltInFilters()

        isLoading = false
    }

    /// Built-in 필터가 없으면 추가
    private func ensureBuiltInFilters() async {
        let builtInFilters = BuiltInFilters.all
        let existingIds = Set(savedViews.map { $0.id })

        for filter in builtInFilters {
            if !existingIds.contains(filter.id) {
                do {
                    try await savedViewRepository.save(filter)
                    savedViews.append(filter)
                } catch {
                    // Built-in 필터 저장 실패는 무시 (다음 실행에 재시도)
                }
            }
        }

        // 정렬
        savedViews.sort()
    }

    // MARK: - SavedView Methods

    /// 저장된 뷰 저장
    func saveSavedView(_ view: SavedView) async {
        do {
            try await savedViewRepository.save(view)
            if let index = savedViews.firstIndex(where: { $0.id == view.id }) {
                savedViews[index] = view
            } else {
                savedViews.append(view)
            }
            savedViews.sort()
        } catch {
            self.error = error
        }
    }

    /// 저장된 뷰 삭제
    func deleteSavedView(id: String) async {
        do {
            try await savedViewRepository.delete(id: id)
            savedViews.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    /// 필터 적용
    func applyFilter(_ filter: FilterDefinition) -> [Task] {
        applyFilterUseCase.execute(
            filter: filter,
            tasks: tasks,
            projects: projects,
            completionLogs: completionLogs
        )
    }

    /// SavedView로 필터 적용
    func filteredTasks(for savedView: SavedView) -> [Task] {
        applyFilter(savedView.definition)
    }

    // MARK: - Computed Properties for Filters

    /// Built-in 필터 목록
    var builtInFilters: [SavedView] {
        savedViews.filter { $0.isBuiltIn }
    }

    /// 사용자 정의 필터 목록
    var customFilters: [SavedView] {
        savedViews.filter { !$0.isBuiltIn }
    }

    func saveSettings(_ newSettings: AppSettings) async {
        do {
            try await storage.saveSettings(newSettings)
            settings = newSettings
        } catch {
            self.error = error
        }
    }

    /// 설정 업데이트 (use-case 기반)
    /// - Parameters:
    ///   - privacyMode: 새 프라이버시 모드 (nil이면 변경 안 함)
    ///   - pinnedProjectId: 새 핀 프로젝트 ID (.some(id)면 설정, .some(nil)이면 제거, nil이면 변경 안 함)
    ///   - lockscreenSelectionMode: 새 잠금화면 선택 모드 (nil이면 변경 안 함)
    ///   - defaultProjectViewType: 새 기본 프로젝트 뷰 타입 (nil이면 변경 안 함)
    ///   - quickAddParsingEnabled: 새 QuickAdd 파싱 활성화 여부 (nil이면 변경 안 함)
    func updateSettings(
        privacyMode: PrivacyMode? = nil,
        pinnedProjectId: OptionalValue<String>? = nil,
        lockscreenSelectionMode: LockscreenSelectionMode? = nil,
        defaultProjectViewType: ProjectViewType? = nil,
        quickAddParsingEnabled: Bool? = nil
    ) async {
        do {
            let updatedSettings = try await updateSettingsUseCase.execute(
                privacyMode: privacyMode,
                pinnedProjectId: pinnedProjectId,
                lockscreenSelectionMode: lockscreenSelectionMode,
                defaultProjectViewType: defaultProjectViewType,
                quickAddParsingEnabled: quickAddParsingEnabled
            )
            settings = updatedSettings
        } catch {
            self.error = error
        }
    }

    // MARK: - Computed Properties

    var activeProjects: [Project] {
        projects.filter { $0.status == .active && !$0.isInbox }
    }

    var pinnedProject: Project? {
        guard let pinnedId = settings.pinnedProjectId else { return nil }
        return projects.first { $0.id == pinnedId }
    }

    func tasksForProject(_ projectId: String) -> [Task] {
        tasks.filter { $0.projectId == projectId }
    }

    func sectionsForProject(_ projectId: String) -> [Section] {
        sections.filter { $0.projectId == projectId }.sorted()
    }

    func task(id: String) -> Task? {
        tasks.first { $0.id == id }
    }

    func tagsForTask(_ task: Task) -> [Tag] {
        tags.filter { task.tagIds.contains($0.id) }
    }

    // MARK: - Tag Methods

    /// 태그 추가
    func saveTag(name: String, colorToken: String? = nil) async throws -> Tag {
        let tag = try await addTagUseCase.execute(name: name, colorToken: colorToken)
        await loadData()
        return tag
    }

    /// 태그 수정
    func updateTag(id: String, name: String? = nil, colorToken: String?? = nil) async throws {
        _ = try await updateTagUseCase.execute(tagId: id, name: name, colorToken: colorToken)
        await loadData()
    }

    /// 태그 삭제
    func deleteTag(id: String) async throws {
        try await deleteTagUseCase.execute(tagId: id)
        await loadData()
    }

    /// 특정 태그를 사용하는 태스크 수
    func taskCountForTag(_ tagId: String) -> Int {
        tasks.filter { $0.tagIds.contains(tagId) }.count
    }

    func isTaskCompleted(_ task: Task, dateKey: DateKey = .today()) -> Bool {
        // rollover 태스크 먼저 검사
        if task.isRollover {
            guard let nextDueAt = task.nextOccurrenceDueAt else {
                return false
            }
            let occurrenceKey = DateKey.from(nextDueAt).value
            return completionLogs.contains {
                $0.taskId == task.id && $0.occurrenceKey == occurrenceKey
            }
        }

        // habitReset 또는 oneOff
        switch task.taskType {
        case .oneOff:
            return completionLogs.contains {
                $0.taskId == task.id && $0.occurrenceKey == CompletionLog.oneOffOccurrenceKey
            }
        case .dailyRecurring:
            return completionLogs.contains {
                $0.taskId == task.id && $0.occurrenceKey == dateKey.value
            }
        }
    }

    // MARK: - Lock Screen Summary

    func lockScreenSummary(topN: Int = 3) -> LockScreenSummary {
        let policy: SelectionPolicy
        if let pinnedId = settings.pinnedProjectId {
            policy = .pinnedFirst(projectId: pinnedId)
        } else {
            policy = .todayOverview
        }

        return outstandingComputer.compute(
            dateKey: .today(),
            policy: policy,
            privacyMode: settings.privacyMode,
            projects: projects,
            tasks: tasks,
            completionLogs: completionLogs,
            topN: topN
        )
    }
}
