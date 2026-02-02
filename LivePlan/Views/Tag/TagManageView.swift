import SwiftUI
import AppCore

/// 태그 관리 뷰
/// - P2-M2-10: 태그 CRUD
/// - ui-style.md 준수: List 기반, SF Symbols 사용
struct TagManageView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var isAddingTagSheet: Bool = false
    @State private var editingTag: Tag? = nil
    @State private var tagToDelete: Tag? = nil
    @State private var isLoading: Bool = false
    @State private var error: Error? = nil

    // MARK: - Computed Properties

    private var tags: [Tag] {
        appState.tags.sortedByName()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("태그 관리")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("완료") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isAddingTagSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("태그 추가")
                    }
                }
                .sheet(isPresented: $isAddingTagSheet) {
                    TagEditSheet(
                        mode: .add,
                        onSave: { name, colorToken in
                            await addTag(name: name, colorToken: colorToken)
                        }
                    )
                }
                .sheet(item: $editingTag) { tag in
                    TagEditSheet(
                        mode: .edit(tag),
                        onSave: { name, colorToken in
                            await updateTag(tag, name: name, colorToken: colorToken)
                        }
                    )
                }
                .confirmationDialog(
                    "태그 삭제",
                    isPresented: Binding(
                        get: { tagToDelete != nil },
                        set: { if !$0 { tagToDelete = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("삭제", role: .destructive) {
                        if let tag = tagToDelete {
                            Task {
                                await deleteTag(tag)
                            }
                        }
                    }
                    Button("취소", role: .cancel) {
                        tagToDelete = nil
                    }
                } message: {
                    if let tag = tagToDelete {
                        let count = appState.taskCountForTag(tag.id)
                        if count > 0 {
                            Text("'\(tag.name)' 태그를 삭제하시겠습니까?\n이 태그가 적용된 \(count)개의 할 일에서 태그가 제거됩니다.")
                        } else {
                            Text("'\(tag.name)' 태그를 삭제하시겠습니까?")
                        }
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
        if tags.isEmpty {
            emptyState
        } else {
            tagList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("태그가 없습니다")
                .font(.headline)

            Text("태그를 추가하여 할 일을 분류하세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                isAddingTagSheet = true
            } label: {
                Label("태그 추가", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var tagList: some View {
        List {
            Section {
                ForEach(tags) { tag in
                    TagRow(
                        tag: tag,
                        taskCount: appState.taskCountForTag(tag.id),
                        onEdit: {
                            editingTag = tag
                        },
                        onDelete: {
                            tagToDelete = tag
                        }
                    )
                }
            } header: {
                Text("전체 태그 (\(tags.count))")
            }

            if let error {
                Section {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Actions

    private func addTag(name: String, colorToken: String?) async {
        isLoading = true
        error = nil

        do {
            _ = try await appState.saveTag(name: name, colorToken: colorToken)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func updateTag(_ tag: Tag, name: String, colorToken: String?) async {
        isLoading = true
        error = nil

        do {
            // colorToken이 nil이면 색상 제거, 값이 있으면 변경
            try await appState.updateTag(
                id: tag.id,
                name: name,
                colorToken: .some(colorToken)
            )
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func deleteTag(_ tag: Tag) async {
        isLoading = true
        error = nil

        do {
            try await appState.deleteTag(id: tag.id)
        } catch {
            self.error = error
        }

        isLoading = false
        tagToDelete = nil
    }
}

// MARK: - Tag Row

private struct TagRow: View {
    let tag: Tag
    let taskCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 색상 인디케이터
            Circle()
                .fill(tagColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(tag.displayLabel)
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
        .accessibilityLabel("\(tag.name) 태그, \(taskCount)개의 할 일")
        .accessibilityHint("스와이프하여 편집 또는 삭제")
    }

    private var tagColor: Color {
        tag.colorToken.flatMap { Color(tokenName: $0) } ?? .gray
    }
}

// MARK: - Tag Edit Sheet

private struct TagEditSheet: View {
    enum Mode: Identifiable {
        case add
        case edit(Tag)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let tag): return tag.id
            }
        }
    }

    let mode: Mode
    let onSave: (String, String?) async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColorToken: String? = nil
    @State private var isSaving: Bool = false
    @State private var error: Error? = nil

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var navigationTitle: String {
        switch mode {
        case .add: return "태그 추가"
        case .edit: return "태그 편집"
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
                    TextField("태그 이름", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("이름")
                }

                Section {
                    colorPicker
                } header: {
                    Text("색상")
                } footer: {
                    Text("색상을 선택하면 태그가 더 잘 구분됩니다")
                }

                if let error {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
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
                if case .edit(let tag) = mode {
                    name = tag.name
                    selectedColorToken = tag.colorToken
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var colorPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
            // 색상 없음 옵션
            colorButton(token: nil, color: .gray.opacity(0.3), isNone: true)

            // 기본 색상 토큰들
            ForEach(Tag.defaultColorTokens, id: \.self) { token in
                if let color = Color(tokenName: token) {
                    colorButton(token: token, color: color, isNone: false)
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func colorButton(token: String?, color: Color, isNone: Bool) -> some View {
        let isSelected = selectedColorToken == token

        Button {
            selectedColorToken = token
        } label: {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 36, height: 36)

                if isNone {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                if isSelected {
                    Circle()
                        .strokeBorder(.primary, lineWidth: 2)
                        .frame(width: 44, height: 44)

                    if !isNone {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isNone ? "색상 없음" : token ?? "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func save() {
        isSaving = true
        error = nil

        Task {
            do {
                await onSave(name, selectedColorToken)
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview("With Tags") {
    TagManageView()
        .environmentObject(AppState())
}

#Preview("Empty") {
    TagManageView()
        .environmentObject(AppState())
}
