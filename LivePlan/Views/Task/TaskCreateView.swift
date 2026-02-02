import SwiftUI
import AppCore

struct TaskCreateView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let projectId: String

    @State private var title = ""
    @State private var taskType: TaskType = .oneOff
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority: Priority = .defaultPriority
    @State private var sectionId: String? = nil
    @State private var isLoading = false
    @State private var error: Error?

    /// 프로젝트의 섹션 목록
    var sections: [Section] {
        appState.sectionsForProject(projectId)
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("할 일 정보") {
                    TextField("할 일", text: $title)

                    Picker("유형", selection: $taskType) {
                        Text("일반").tag(TaskType.oneOff)
                        Text("매일 반복").tag(TaskType.dailyRecurring)
                    }
                    .pickerStyle(.segmented)

                    PriorityFormRow(priority: $priority)
                }

                // M2-11: 섹션 선택 (섹션이 있을 때만 표시)
                if !sections.isEmpty {
                    Section("섹션") {
                        SectionFormRow(
                            selectedSectionId: $sectionId,
                            sections: sections
                        )
                    }
                }

                if taskType == .oneOff {
                    Section("마감일 (선택)") {
                        Toggle("마감일 설정", isOn: $hasDueDate)

                        if hasDueDate {
                            DatePicker("마감일", selection: $dueDate, displayedComponents: .date)
                        }
                    }
                }

                if let error {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("새 할 일")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        createTask()
                    }
                    .disabled(!isValid || isLoading)
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }

    private func createTask() {
        isLoading = true
        error = nil

        Task {
            do {
                _ = try await appState.addTaskUseCase.execute(
                    title: title,
                    projectId: projectId,
                    taskType: taskType,
                    dueDate: (taskType == .oneOff && hasDueDate) ? dueDate : nil,
                    priority: priority,
                    sectionId: sectionId
                )
                await appState.loadData()
                dismiss()
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TaskCreateView(projectId: "test")
        .environmentObject(AppState())
}
