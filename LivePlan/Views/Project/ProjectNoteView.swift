import SwiftUI
import AppCore

/// 프로젝트 노트 편집 화면
/// - P2-M2-12: TextEditor로 프로젝트 노트 편집
/// - ui-style.md 준수: 기본 SwiftUI 구성요소, SF Symbols 사용
struct ProjectNoteView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let project: Project

    // MARK: - State

    @State private var note: String = ""
    @State private var isSaving: Bool = false
    @State private var error: Error? = nil

    // MARK: - Computed Properties

    private var hasChanges: Bool {
        note != (project.note ?? "")
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                editorView

                if let error {
                    errorView(error)
                }
            }
            .navigationTitle("프로젝트 노트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveNote()
                    }
                    .disabled(!hasChanges || isSaving)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView("저장 중...")
                }
            }
            .onAppear {
                note = project.note ?? ""
            }
        }
    }

    // MARK: - Subviews

    private var editorView: some View {
        ZStack(alignment: .topLeading) {
            if note.isEmpty {
                Text("프로젝트에 대한 메모를 입력하세요...")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
            }

            TextEditor(text: $note)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
    }

    private func errorView(_ error: Error) -> some View {
        Text(error.localizedDescription)
            .font(.caption)
            .foregroundStyle(.red)
            .padding()
    }

    // MARK: - Actions

    private func saveNote() {
        isSaving = true
        error = nil

        Task {
            do {
                let noteValue: OptionalValue<String> = note.isEmpty ? .none : .some(note)
                _ = try await appState.updateProjectUseCase.execute(
                    projectId: project.id,
                    note: noteValue
                )
                await appState.loadData()
                dismiss()
            } catch {
                self.error = error
                isSaving = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let project = Project(
        title: "테스트 프로젝트",
        startDate: Date(),
        note: "이것은 샘플 프로젝트 노트입니다.\n\n여러 줄을 입력할 수 있습니다."
    )

    return ProjectNoteView(project: project)
        .environmentObject(AppState())
}
