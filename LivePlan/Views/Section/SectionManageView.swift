import SwiftUI
import AppCore

/// 섹션 관리 뷰
/// - P2-M2-09: 섹션 CRUD, 순서 변경
/// - ui-style.md 준수: List 기반, SF Symbols 사용
struct SectionManageView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let projectId: String

    // MARK: - State

    @State private var isAddingSectionSheet: Bool = false
    @State private var editingSection: Section? = nil
    @State private var sectionToDelete: Section? = nil
    @State private var isLoading: Bool = false
    @State private var error: Error? = nil

    // MARK: - Computed Properties

    private var sections: [Section] {
        appState.sectionsForProject(projectId)
    }

    private var projectName: String {
        appState.projects.first { $0.id == projectId }?.title ?? "프로젝트"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("섹션 관리")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("완료") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isAddingSectionSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("섹션 추가")
                    }
                }
                .sheet(isPresented: $isAddingSectionSheet) {
                    SectionEditSheet(
                        mode: .add,
                        projectId: projectId,
                        onSave: { title in
                            await addSection(title: title)
                        }
                    )
                }
                .sheet(item: $editingSection) { section in
                    SectionEditSheet(
                        mode: .edit(section),
                        projectId: projectId,
                        onSave: { title in
                            await updateSection(section, title: title)
                        }
                    )
                }
                .confirmationDialog(
                    "섹션 삭제",
                    isPresented: Binding(
                        get: { sectionToDelete != nil },
                        set: { if !$0 { sectionToDelete = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("삭제", role: .destructive) {
                        if let section = sectionToDelete {
                            Task {
                                await deleteSection(section)
                            }
                        }
                    }
                    Button("취소", role: .cancel) {
                        sectionToDelete = nil
                    }
                } message: {
                    if let section = sectionToDelete {
                        Text("'\(section.title)' 섹션을 삭제하시겠습니까?\n섹션 내 할 일은 미분류로 이동됩니다.")
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

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if sections.isEmpty {
            emptyState
        } else {
            sectionList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("섹션이 없습니다")
                .font(.headline)

            Text("섹션을 추가하여 할 일을 그룹으로 정리하세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                isAddingSectionSheet = true
            } label: {
                Label("섹션 추가", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var sectionList: some View {
        List {
            Section {
                ForEach(sections) { section in
                    SectionRow(
                        section: section,
                        taskCount: taskCount(for: section),
                        onEdit: {
                            editingSection = section
                        },
                        onDelete: {
                            sectionToDelete = section
                        }
                    )
                }
                .onMove(perform: moveSections)
            } header: {
                Text("\(projectName) 프로젝트의 섹션")
            } footer: {
                Text("드래그하여 순서를 변경하세요")
                    .font(.caption)
            }

            if let error {
                Section {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Helpers

    private func taskCount(for section: Section) -> Int {
        appState.tasks.filter { $0.sectionId == section.id }.count
    }

    // MARK: - Actions

    private func addSection(title: String) async {
        isLoading = true
        error = nil

        do {
            _ = try await appState.addSectionUseCase.execute(
                title: title,
                projectId: projectId
            )
            await appState.loadData()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func updateSection(_ section: Section, title: String) async {
        isLoading = true
        error = nil

        do {
            var updatedSection = section
            updatedSection.title = title
            updatedSection.updatedAt = Date()
            try await appState.sectionRepository.save(updatedSection)
            await appState.loadData()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func deleteSection(_ section: Section) async {
        isLoading = true
        error = nil

        do {
            try await appState.sectionRepository.delete(id: section.id)
            await appState.loadData()
        } catch {
            self.error = error
        }

        isLoading = false
        sectionToDelete = nil
    }

    private func moveSections(from source: IndexSet, to destination: Int) {
        Task {
            isLoading = true
            error = nil

            var reorderedSections = sections
            reorderedSections.move(fromOffsets: source, toOffset: destination)

            // Update orderIndex for all sections
            for (index, section) in reorderedSections.enumerated() {
                var updatedSection = section
                updatedSection.orderIndex = index
                updatedSection.updatedAt = Date()

                do {
                    try await appState.sectionRepository.save(updatedSection)
                } catch {
                    self.error = error
                    break
                }
            }

            await appState.loadData()
            isLoading = false
        }
    }
}

// MARK: - Section Row

private struct SectionRow: View {
    let section: Section
    let taskCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .lineLimit(1)

                Text("\(taskCount)개의 할 일")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("삭제", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("편집", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(section.title) 섹션, \(taskCount)개의 할 일")
        .accessibilityHint("스와이프하여 편집 또는 삭제")
    }
}

// MARK: - Section Edit Sheet

private struct SectionEditSheet: View {
    enum Mode: Identifiable {
        case add
        case edit(Section)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let section): return section.id
            }
        }
    }

    let mode: Mode
    let projectId: String
    let onSave: (String) async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var isSaving: Bool = false

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var navigationTitle: String {
        switch mode {
        case .add: return "섹션 추가"
        case .edit: return "섹션 편집"
        }
    }

    private var saveButtonTitle: String {
        switch mode {
        case .add: return "추가"
        case .edit: return "저장"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("섹션 이름", text: $title)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("섹션 이름")
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView()
                }
            }
            .onAppear {
                if case .edit(let section) = mode {
                    title = section.title
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        isSaving = true

        Task {
            await onSave(title)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("With Sections") {
    SectionManageView(projectId: "p1")
        .environmentObject(AppState())
}

#Preview("Empty") {
    SectionManageView(projectId: "empty-project")
        .environmentObject(AppState())
}
