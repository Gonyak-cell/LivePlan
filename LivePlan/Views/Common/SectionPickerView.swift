import SwiftUI
import AppCore

/// 섹션 선택 Picker
/// - M2-UI: Section 선택 UI 컴포넌트
/// - ui-style.md 준수: SF Symbols 사용, Dynamic Type 지원
/// - 단일 선택, "미분류" 옵션 포함
struct SectionPickerView: View {
    @Binding var selectedSectionId: String?
    let sections: [Section]

    var body: some View {
        List {
            // "미분류" 옵션
            Button {
                selectedSectionId = nil
            } label: {
                HStack {
                    Image(systemName: "tray")
                        .foregroundStyle(.secondary)
                    Text("미분류")
                    Spacer()
                    if selectedSectionId == nil {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("미분류")
            .accessibilityAddTraits(selectedSectionId == nil ? .isSelected : [])

            // 섹션 목록
            ForEach(sections.sorted()) { section in
                Button {
                    selectedSectionId = section.id
                } label: {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        Text(section.title)
                        Spacer()
                        if selectedSectionId == section.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(section.title) 섹션")
                .accessibilityAddTraits(selectedSectionId == section.id ? .isSelected : [])
            }
        }
    }
}

// MARK: - Sheet Wrapper

/// 시트로 표시되는 섹션 선택기
struct SectionPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSectionId: String?
    let sections: [Section]

    var body: some View {
        NavigationStack {
            SectionPickerView(
                selectedSectionId: $selectedSectionId,
                sections: sections
            )
            .navigationTitle("섹션 선택")
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

/// Form 내 섹션 선택 행
struct SectionFormRow: View {
    @Binding var selectedSectionId: String?
    let sections: [Section]
    var label: String = "섹션"

    @State private var showPicker: Bool = false

    private var selectedSection: Section? {
        sections.first { $0.id == selectedSectionId }
    }

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text(label)
                    .foregroundStyle(.primary)

                Spacer()

                if let section = selectedSection {
                    Text(section.title)
                        .foregroundStyle(.secondary)
                } else {
                    Text("미분류")
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            SectionPickerSheet(
                selectedSectionId: $selectedSectionId,
                sections: sections
            )
            .presentationDetents([.medium])
        }
        .accessibilityLabel("\(label): \(selectedSection?.title ?? "미분류")")
        .accessibilityHint("탭하여 섹션 선택")
    }
}

// MARK: - Preview

private let previewSections = [
    Section(id: "1", projectId: "p1", title: "디자인", orderIndex: 0),
    Section(id: "2", projectId: "p1", title: "개발", orderIndex: 1),
    Section(id: "3", projectId: "p1", title: "테스트", orderIndex: 2)
]

private struct PickerPreview: View {
    @State private var selectedId: String? = nil

    var body: some View {
        SectionPickerView(
            selectedSectionId: $selectedId,
            sections: previewSections
        )
    }
}

#Preview("Section Picker") {
    PickerPreview()
}

private struct FormPreview: View {
    @State private var selectedId: String? = "1"

    var body: some View {
        Form {
            Section {
                SectionFormRow(
                    selectedSectionId: $selectedId,
                    sections: previewSections
                )
            }

            Section("선택된 섹션") {
                if let id = selectedId,
                   let section = previewSections.first(where: { $0.id == id }) {
                    Text(section.title)
                } else {
                    Text("미분류")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Form Row") {
    FormPreview()
}

#Preview("Sheet") {
    struct SheetPreview: View {
        @State private var showSheet = true
        @State private var selectedId: String? = nil

        var body: some View {
            Button("섹션 선택") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                SectionPickerSheet(
                    selectedSectionId: $selectedId,
                    sections: previewSections
                )
            }
        }
    }

    return SheetPreview()
}
