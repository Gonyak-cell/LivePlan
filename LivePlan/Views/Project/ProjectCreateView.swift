import SwiftUI
import AppCore

struct ProjectCreateView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var startDate = Date()
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var isLoading = false
    @State private var error: Error?

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!hasDueDate || dueDate >= startDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("프로젝트 정보") {
                    TextField("프로젝트 이름", text: $title)

                    DatePicker("시작일", selection: $startDate, displayedComponents: .date)
                }

                Section("마감일 (선택)") {
                    Toggle("마감일 설정", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("마감일", selection: $dueDate, in: startDate..., displayedComponents: .date)
                    }
                }

                if let error {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("새 프로젝트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("만들기") {
                        createProject()
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

    private func createProject() {
        isLoading = true
        error = nil

        Task {
            do {
                _ = try await appState.addProjectUseCase.execute(
                    title: title,
                    startDate: startDate,
                    dueDate: hasDueDate ? dueDate : nil
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
    ProjectCreateView()
        .environmentObject(AppState())
}
