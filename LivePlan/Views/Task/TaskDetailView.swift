import SwiftUI
import AppCore

/// 태스크 상세 보기/편집 화면
/// - P2-M2-08: 모든 필드 편집, 노트, 의존성 표시
/// - ui-style.md 준수: Form 기반, SF Symbols 사용
struct TaskDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let task: Task

    // MARK: - State

    @State private var title: String = ""
    @State private var taskType: TaskType = .oneOff
    @State private var priority: Priority = .defaultPriority
    @State private var workflowState: WorkflowState = .defaultState
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var sectionId: String? = nil
    @State private var tagIds: [String] = []
    @State private var note: String = ""

    // UI State
    @State private var isSaving: Bool = false
    @State private var error: Error? = nil
    @State private var showingDeleteConfirmation: Bool = false

    // MARK: - Computed Properties

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasChanges: Bool {
        title != task.title ||
        taskType != task.taskType ||
        priority != task.priority ||
        workflowState != task.workflowState ||
        hasDueDate != (task.dueDate != nil) ||
        (hasDueDate && dueDate != (task.dueDate ?? Date())) ||
        sectionId != task.sectionId ||
        tagIds != task.tagIds ||
        note != (task.note ?? "")
    }

    private var sections: [Section] {
        appState.sectionsForProject(task.projectId)
    }

    private var blockedByTasks: [Task] {
        task.blockedByTaskIds.compactMap { appState.task(id: $0) }
    }

    private var projectName: String {
        appState.projects.first { $0.id == task.projectId }?.title ?? "알 수 없음"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                dateSection
                organizationSection
                noteSection
                dependenciesSection
                actionsSection

                if let error {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("할 일 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveChanges()
                    }
                    .disabled(!isValid || !hasChanges || isSaving)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView("저장 중...")
                }
            }
            .onAppear {
                loadTaskData()
            }
            .confirmationDialog(
                "이 할 일을 삭제하시겠습니까?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("삭제", role: .destructive) {
                    deleteTask()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("삭제된 할 일은 복구할 수 없습니다.")
            }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section("기본 정보") {
            TextField("할 일", text: $title)

            Picker("유형", selection: $taskType) {
                Text("일반").tag(TaskType.oneOff)
                Text("매일 반복").tag(TaskType.dailyRecurring)
            }
            .pickerStyle(.segmented)

            PriorityFormRow(priority: $priority)

            Picker("상태", selection: $workflowState) {
                Text("할 일").tag(WorkflowState.todo)
                Text("진행 중").tag(WorkflowState.doing)
                Text("완료").tag(WorkflowState.done)
            }
            .pickerStyle(.segmented)
        }
    }

    private var dateSection: some View {
        Section("일정") {
            Toggle("마감일", isOn: $hasDueDate)

            if hasDueDate {
                DatePicker("마감일", selection: $dueDate, displayedComponents: .date)
            }
        }
    }

    private var organizationSection: some View {
        Section("구성") {
            // 프로젝트 (읽기 전용)
            HStack {
                Text("프로젝트")
                Spacer()
                Text(projectName)
                    .foregroundStyle(.secondary)
            }

            // 섹션 선택
            if !sections.isEmpty {
                SectionFormRow(
                    selectedSectionId: $sectionId,
                    sections: sections
                )
            }

            // 태그 선택
            TagFormRow(
                selectedTagIds: $tagIds,
                availableTags: appState.tags,
                onCreateTag: { name in
                    do {
                        return try await appState.addTagUseCase.execute(name: name)
                    } catch {
                        return nil
                    }
                }
            )
        }
    }

    private var noteSection: some View {
        Section("노트") {
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("노트 입력...")
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $note)
                    .frame(minHeight: 100)
                    .opacity(note.isEmpty ? 0.25 : 1)
            }
        }
    }

    private var dependenciesSection: some View {
        Section("선행 태스크") {
            if blockedByTasks.isEmpty {
                Text("없음")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(blockedByTasks, id: \.id) { blockedTask in
                    HStack {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundStyle(.secondary)
                        Text(blockedTask.title)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        Section {
            // 시작 버튼 (todo 상태일 때만)
            if task.workflowState == .todo {
                Button {
                    startTask()
                } label: {
                    Label("작업 시작", systemImage: "play.fill")
                }
            }

            // 삭제 버튼
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func loadTaskData() {
        title = task.title
        taskType = task.taskType
        priority = task.priority
        workflowState = task.workflowState
        hasDueDate = task.dueDate != nil
        dueDate = task.dueDate ?? Date()
        sectionId = task.sectionId
        tagIds = task.tagIds
        note = task.note ?? ""
    }

    private func saveChanges() {
        isSaving = true
        error = nil

        Task {
            do {
                _ = try await appState.updateTaskUseCase.execute(
                    taskId: task.id,
                    title: title != task.title ? title : nil,
                    taskType: taskType != task.taskType ? taskType : nil,
                    dueDate: dueDateChanged ? dueDateValue : nil,
                    priority: priority != task.priority ? priority : nil,
                    workflowState: workflowState != task.workflowState ? workflowState : nil,
                    sectionId: sectionId != task.sectionId ? .value(sectionId) : nil,
                    tagIds: tagIds != task.tagIds ? tagIds : nil,
                    note: noteChanged ? noteValue : nil
                )
                await appState.loadData()
                dismiss()
            } catch {
                self.error = error
                isSaving = false
            }
        }
    }

    private var dueDateChanged: Bool {
        let hadDueDate = task.dueDate != nil
        if hasDueDate != hadDueDate { return true }
        if hasDueDate, let originalDate = task.dueDate {
            return !Calendar.current.isDate(dueDate, inSameDayAs: originalDate)
        }
        return false
    }

    private var dueDateValue: OptionalValue<Date> {
        hasDueDate ? .some(dueDate) : .none
    }

    private var noteChanged: Bool {
        note != (task.note ?? "")
    }

    private var noteValue: OptionalValue<String> {
        note.isEmpty ? .none : .some(note)
    }

    private func startTask() {
        Task {
            do {
                _ = try await appState.startTaskUseCase.execute(taskId: task.id)
                workflowState = .doing
                await appState.loadData()
            } catch {
                self.error = error
            }
        }
    }

    private func deleteTask() {
        Task {
            do {
                try await appState.taskRepository.delete(id: task.id)
                await appState.loadData()
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let task = Task(
        id: "1",
        projectId: "p1",
        title: "샘플 태스크",
        taskType: .oneOff,
        priority: .p2,
        workflowState: .todo,
        dueDate: Date().addingTimeInterval(86400 * 3),
        note: "이것은 샘플 노트입니다."
    )

    return TaskDetailView(task: task)
        .environmentObject(AppState())
}
