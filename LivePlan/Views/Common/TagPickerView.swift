import SwiftUI
import AppCore

/// 태그 선택/생성 Picker
/// - M2-UI-5: Tag 관리 UI 컴포넌트
/// - ui-style.md 준수: SF Symbols 사용, Dynamic Type 지원
/// - 다중 선택 지원, 새 태그 생성 가능
struct TagPickerView: View {
    @Binding var selectedTagIds: [String]
    let availableTags: [Tag]
    var onCreateTag: ((String) async -> Tag?)? = nil

    @State private var searchText: String = ""
    @State private var isCreating: Bool = false
    @State private var showCreateField: Bool = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // 검색/생성 필드
            searchField

            // 선택된 태그 표시
            if !selectedTagIds.isEmpty {
                selectedTagsSection
            }

            // 태그 목록
            tagList
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("태그 검색 또는 생성", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .submitLabel(.done)
                .onSubmit {
                    handleSearchSubmit()
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityLabel("태그 검색")
    }

    // MARK: - Selected Tags Section

    private var selectedTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("선택됨")
                .font(.caption)
                .foregroundStyle(.secondary)

            EditableTagChipsView(
                selectedTagIds: $selectedTagIds,
                allTags: availableTags
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tag List

    private var tagList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !filteredTags.isEmpty || canCreateNewTag {
                Text("태그")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                LazyVStack(spacing: 4) {
                    // 새 태그 생성 옵션
                    if canCreateNewTag {
                        createNewTagRow
                    }

                    // 기존 태그 목록
                    ForEach(filteredTags) { tag in
                        tagRow(tag)
                    }

                    if filteredTags.isEmpty && !canCreateNewTag && !searchText.isEmpty {
                        noResultsView
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tag Row

    private func tagRow(_ tag: Tag) -> some View {
        let isSelected = selectedTagIds.contains(tag.id)

        return Button {
            toggleTag(tag)
        } label: {
            HStack {
                TagChipView(tag: tag, isSelected: isSelected)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tag.name) 태그")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "탭하여 선택 해제" : "탭하여 선택")
    }

    // MARK: - Create New Tag Row

    private var createNewTagRow: some View {
        Button {
            Task {
                await createNewTag()
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)

                Text("\"\(cleanedSearchText)\" 태그 만들기")
                    .font(.subheadline)

                Spacer()

                if isCreating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .disabled(isCreating)
        .accessibilityLabel("\(cleanedSearchText) 태그 만들기")
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        Text("일치하는 태그가 없습니다")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }

    // MARK: - Computed Properties

    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return availableTags.sortedByName()
        }

        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        return availableTags
            .filter { $0.normalizedName.contains(query) }
            .sortedByName()
    }

    private var cleanedSearchText: String {
        var text = searchText.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("#") {
            text = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return text
    }

    private var canCreateNewTag: Bool {
        guard !cleanedSearchText.isEmpty else { return false }
        guard onCreateTag != nil else { return false }

        // 이미 같은 이름의 태그가 있는지 확인
        return !availableTags.containsName(cleanedSearchText)
    }

    // MARK: - Actions

    private func toggleTag(_ tag: Tag) {
        if let index = selectedTagIds.firstIndex(of: tag.id) {
            selectedTagIds.remove(at: index)
        } else {
            selectedTagIds.append(tag.id)
        }
    }

    private func handleSearchSubmit() {
        if canCreateNewTag {
            Task {
                await createNewTag()
            }
        } else if let matchingTag = filteredTags.first {
            toggleTag(matchingTag)
            searchText = ""
        }
    }

    private func createNewTag() async {
        guard let onCreate = onCreateTag, !cleanedSearchText.isEmpty else { return }

        isCreating = true
        defer { isCreating = false }

        if let newTag = await onCreate(cleanedSearchText) {
            selectedTagIds.append(newTag.id)
            searchText = ""
        }
    }
}

// MARK: - Sheet Wrapper

/// 시트로 표시되는 태그 선택기
struct TagPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTagIds: [String]
    let availableTags: [Tag]
    var onCreateTag: ((String) async -> Tag?)? = nil

    var body: some View {
        NavigationStack {
            TagPickerView(
                selectedTagIds: $selectedTagIds,
                availableTags: availableTags,
                onCreateTag: onCreateTag
            )
            .padding()
            .navigationTitle("태그 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Form Row Helper

/// Form 내 태그 선택 행
struct TagFormRow: View {
    @Binding var selectedTagIds: [String]
    let availableTags: [Tag]
    var onCreateTag: ((String) async -> Tag?)? = nil
    var label: String = "태그"

    @State private var showPicker: Bool = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text(label)
                    .foregroundStyle(.primary)

                Spacer()

                if selectedTagIds.isEmpty {
                    Text("없음")
                        .foregroundStyle(.secondary)
                } else {
                    selectedTagsPreview
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            TagPickerSheet(
                selectedTagIds: $selectedTagIds,
                availableTags: availableTags,
                onCreateTag: onCreateTag
            )
            .presentationDetents([.medium, .large])
        }
        .accessibilityLabel("\(label): \(selectedTagIds.count)개 선택됨")
        .accessibilityHint("탭하여 태그 선택")
    }

    private var selectedTagsPreview: some View {
        let selectedTags = availableTags.filter { selectedTagIds.contains($0.id) }
        let displayCount = min(selectedTags.count, 2)
        let remaining = selectedTags.count - displayCount

        return HStack(spacing: 4) {
            ForEach(selectedTags.prefix(displayCount)) { tag in
                Text(tag.displayLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if remaining > 0 {
                Text("+\(remaining)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Inline Picker (Compact)

/// 인라인 태그 선택기 (컴팩트한 공간용)
struct TagInlinePicker: View {
    @Binding var selectedTagIds: [String]
    let availableTags: [Tag]
    var maxVisible: Int = 5

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(visibleTags) { tag in
                    Button {
                        toggleTag(tag)
                    } label: {
                        TagChipView(
                            tag: tag,
                            isSelected: selectedTagIds.contains(tag.id)
                        )
                    }
                    .buttonStyle(.plain)
                }

                if availableTags.count > maxVisible {
                    Text("+\(availableTags.count - maxVisible)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                }
            }
        }
    }

    private var visibleTags: [Tag] {
        Array(availableTags.sortedByName().prefix(maxVisible))
    }

    private func toggleTag(_ tag: Tag) {
        if let index = selectedTagIds.firstIndex(of: tag.id) {
            selectedTagIds.remove(at: index)
        } else {
            selectedTagIds.append(tag.id)
        }
    }
}

// MARK: - Preview

private let previewTags = [
    Tag(id: "1", name: "업무", colorToken: "blue"),
    Tag(id: "2", name: "긴급", colorToken: "red"),
    Tag(id: "3", name: "개인", colorToken: "green"),
    Tag(id: "4", name: "회의", colorToken: "purple"),
    Tag(id: "5", name: "리뷰", colorToken: "orange"),
    Tag(id: "6", name: "프로젝트", colorToken: "pink")
]

private struct PickerPreview: View {
    @State private var selectedIds: [String] = ["1", "2"]

    var body: some View {
        VStack {
            TagPickerView(
                selectedTagIds: $selectedIds,
                availableTags: previewTags,
                onCreateTag: { name in
                    // 시뮬레이션: 새 태그 생성
                    try? await Task.sleep(for: .milliseconds(500))
                    return Tag(name: name)
                }
            )

            Divider()
                .padding(.vertical)

            Text("선택됨: \(selectedIds.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview("Tag Picker") {
    PickerPreview()
}

private struct FormPreview: View {
    @State private var selectedIds: [String] = []

    var body: some View {
        Form {
            Section {
                TagFormRow(
                    selectedTagIds: $selectedIds,
                    availableTags: previewTags,
                    onCreateTag: { name in
                        Tag(name: name)
                    }
                )
            }

            Section("선택된 태그") {
                if selectedIds.isEmpty {
                    Text("없음")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selectedIds, id: \.self) { id in
                        if let tag = previewTags.first(where: { $0.id == id }) {
                            Text(tag.displayLabel)
                        }
                    }
                }
            }
        }
    }
}

#Preview("Form Row") {
    FormPreview()
}

private struct InlinePreview: View {
    @State private var selectedIds: [String] = ["1"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Inline Picker")
                .font(.headline)

            TagInlinePicker(
                selectedTagIds: $selectedIds,
                availableTags: previewTags
            )

            Text("선택됨: \(selectedIds.count)개")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview("Inline Picker") {
    InlinePreview()
}

#Preview("Sheet") {
    struct SheetPreview: View {
        @State private var showSheet = true
        @State private var selectedIds: [String] = []

        var body: some View {
            Button("태그 선택") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                TagPickerSheet(
                    selectedTagIds: $selectedIds,
                    availableTags: previewTags,
                    onCreateTag: { name in Tag(name: name) }
                )
            }
        }
    }

    return SheetPreview()
}
