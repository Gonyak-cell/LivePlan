import SwiftUI
import AppCore

/// 필터 조건 빌더 뷰
struct FilterBuilderView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var definition: FilterDefinition

    // 로컬 상태
    @State private var selectedProjectIds: Set<String> = []
    @State private var selectedSectionIds: Set<String> = []
    @State private var selectedTagIds: Set<String> = []
    @State private var priorityAtLeast: Priority?
    @State private var priorityAtMost: Priority?
    @State private var stateIn: Set<WorkflowState>?
    @State private var dueRange: DueRange?
    @State private var recurringOption: RecurringOption = .all
    @State private var excludeBlocked: Bool = true

    enum RecurringOption: String, CaseIterable {
        case all = "전체"
        case recurringOnly = "반복만"
        case nonRecurringOnly = "반복 제외"

        var includeRecurring: Bool? {
            switch self {
            case .all: return nil
            case .recurringOnly: return true
            case .nonRecurringOnly: return false
            }
        }
    }

    var body: some View {
        Form {
            // 프로젝트 필터
            Section("프로젝트") {
                NavigationLink {
                    ProjectMultiSelectView(selection: $selectedProjectIds)
                } label: {
                    HStack {
                        Text("프로젝트 선택")
                        Spacer()
                        if selectedProjectIds.isEmpty {
                            Text("전체")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(selectedProjectIds.count)개 선택")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            // 섹션 필터 (프로젝트가 선택된 경우에만 표시)
            if !selectedProjectIds.isEmpty && !availableSections.isEmpty {
                Section("섹션") {
                    NavigationLink {
                        SectionMultiSelectView(
                            selection: $selectedSectionIds,
                            sections: availableSections
                        )
                    } label: {
                        HStack {
                            Text("섹션 선택")
                            Spacer()
                            if selectedSectionIds.isEmpty {
                                Text("전체")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(selectedSectionIds.count)개 선택")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            // 태그 필터
            Section("태그") {
                NavigationLink {
                    TagMultiSelectView(selection: $selectedTagIds)
                } label: {
                    HStack {
                        Text("태그 선택")
                        Spacer()
                        if selectedTagIds.isEmpty {
                            Text("전체")
                                .foregroundStyle(.secondary)
                        } else {
                            selectedTagsPreview
                        }
                    }
                }
            }

            // 우선순위 필터
            Section("우선순위") {
                Picker("최소 우선순위", selection: $priorityAtLeast) {
                    Text("전체").tag(nil as Priority?)
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Text(priority.label).tag(priority as Priority?)
                    }
                }

                Picker("최대 우선순위", selection: $priorityAtMost) {
                    Text("전체").tag(nil as Priority?)
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Text(priority.label).tag(priority as Priority?)
                    }
                }
            }

            // 상태 필터
            Section("상태") {
                WorkflowStatePickerView(selection: $stateIn)
            }

            // 마감일 필터
            Section("마감일") {
                DueRangePickerView(selection: $dueRange)
            }

            // 반복 필터
            Section("반복") {
                Picker("반복 태스크", selection: $recurringOption) {
                    ForEach(RecurringOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            // 차단 필터
            Section {
                Toggle("차단된 태스크 제외", isOn: $excludeBlocked)
            } footer: {
                Text("선행 태스크가 완료되지 않은 태스크를 제외합니다")
            }
        }
        .navigationTitle("조건 설정")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFromDefinition()
        }
        .onChange(of: selectedProjectIds) { _, newValue in
            // 프로젝트가 변경되면 해당 프로젝트에 속하지 않는 섹션 제거
            let validSectionIds = Set(availableSectionsFor(projectIds: newValue).map(\.id))
            selectedSectionIds = selectedSectionIds.intersection(validSectionIds)
            updateDefinition()
        }
        .onChange(of: selectedSectionIds) { _, _ in updateDefinition() }
        .onChange(of: selectedTagIds) { _, _ in updateDefinition() }
        .onChange(of: priorityAtLeast) { _, _ in updateDefinition() }
        .onChange(of: priorityAtMost) { _, _ in updateDefinition() }
        .onChange(of: stateIn) { _, _ in updateDefinition() }
        .onChange(of: dueRange) { _, _ in updateDefinition() }
        .onChange(of: recurringOption) { _, _ in updateDefinition() }
        .onChange(of: excludeBlocked) { _, _ in updateDefinition() }
    }

    /// 선택된 프로젝트들에 속한 섹션 목록
    private var availableSections: [Section] {
        availableSectionsFor(projectIds: selectedProjectIds)
    }

    /// 특정 프로젝트 ID 집합에 속한 섹션 목록
    private func availableSectionsFor(projectIds: Set<String>) -> [Section] {
        appState.sections.filter { projectIds.contains($0.projectId) }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    private func loadFromDefinition() {
        selectedProjectIds = Set(definition.includeProjectIds ?? [])
        selectedSectionIds = Set(definition.includeSectionIds ?? [])
        selectedTagIds = Set(definition.includeTagIds ?? [])
        priorityAtLeast = definition.priorityAtLeast
        priorityAtMost = definition.priorityAtMost
        stateIn = definition.stateIn
        dueRange = definition.dueRange
        excludeBlocked = definition.excludeBlocked

        if let includeRecurring = definition.includeRecurring {
            recurringOption = includeRecurring ? .recurringOnly : .nonRecurringOnly
        } else {
            recurringOption = .all
        }
    }

    private func updateDefinition() {
        definition = FilterDefinition(
            includeProjectIds: selectedProjectIds.isEmpty ? nil : Array(selectedProjectIds),
            includeSectionIds: selectedSectionIds.isEmpty ? nil : Array(selectedSectionIds),
            includeTagIds: selectedTagIds.isEmpty ? nil : Array(selectedTagIds),
            priorityAtLeast: priorityAtLeast,
            priorityAtMost: priorityAtMost,
            stateIn: stateIn,
            dueRange: dueRange,
            includeRecurring: recurringOption.includeRecurring,
            excludeBlocked: excludeBlocked
        )
    }

    /// 선택된 태그 미리보기 (최대 2개 이름 + 나머지 개수)
    private var selectedTagsPreview: some View {
        let selectedTags = appState.tags.filter { selectedTagIds.contains($0.id) }.sortedByName()
        let displayCount = min(selectedTags.count, 2)
        let remaining = selectedTags.count - displayCount

        return HStack(spacing: 4) {
            ForEach(selectedTags.prefix(displayCount)) { tag in
                Text(tag.displayLabel)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            if remaining > 0 {
                Text("+\(remaining)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Project Multi-Select View

struct ProjectMultiSelectView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selection: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(appState.activeProjects) { project in
                Button {
                    toggleSelection(project.id)
                } label: {
                    HStack {
                        Text(project.title)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection.contains(project.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("프로젝트 선택")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("완료") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("전체 해제") {
                    selection.removeAll()
                }
                .disabled(selection.isEmpty)
            }
        }
    }

    private func toggleSelection(_ id: String) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }
}

// MARK: - Section Multi-Select View

struct SectionMultiSelectView: View {
    @Binding var selection: Set<String>
    let sections: [Section]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    /// 프로젝트별 섹션 그룹
    private var sectionsByProject: [(project: Project, sections: [Section])] {
        let projectIds = Set(sections.map(\.projectId))
        let projects = appState.projects.filter { projectIds.contains($0.id) }

        return projects.compactMap { project in
            let projectSections = sections.filter { $0.projectId == project.id }
            guard !projectSections.isEmpty else { return nil }
            return (project: project, sections: projectSections.sorted { $0.orderIndex < $1.orderIndex })
        }
    }

    var body: some View {
        List {
            if sectionsByProject.count == 1 {
                // 프로젝트가 1개면 그룹핑 없이 표시
                ForEach(sections) { section in
                    sectionButton(section)
                }
            } else {
                // 여러 프로젝트면 프로젝트별 그룹핑
                ForEach(sectionsByProject, id: \.project.id) { group in
                    Section(group.project.title) {
                        ForEach(group.sections) { section in
                            sectionButton(section)
                        }
                    }
                }
            }
        }
        .navigationTitle("섹션 선택")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("완료") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("전체 해제") {
                    selection.removeAll()
                }
                .disabled(selection.isEmpty)
            }
        }
    }

    @ViewBuilder
    private func sectionButton(_ section: Section) -> some View {
        Button {
            toggleSelection(section.id)
        } label: {
            HStack {
                Image(systemName: "rectangle.3.group")
                    .foregroundStyle(.purple)
                Text(section.title)
                    .foregroundStyle(.primary)
                Spacer()
                if selection.contains(section.id) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private func toggleSelection(_ id: String) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }
}

// MARK: - Tag Multi-Select View

struct TagMultiSelectView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selection: Set<String>
    @Environment(\.dismiss) private var dismiss

    /// 정렬된 태그 목록 (Tag 엔티티 사용)
    private var sortedTags: [Tag] {
        appState.tags.sortedByName()
    }

    var body: some View {
        List {
            if sortedTags.isEmpty {
                Text("태그가 없습니다")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedTags) { tag in
                    Button {
                        toggleSelection(tag.id)
                    } label: {
                        HStack {
                            Text(tag.displayLabel)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selection.contains(tag.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("태그 선택")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("완료") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("전체 해제") {
                    selection.removeAll()
                }
                .disabled(selection.isEmpty)
            }
        }
    }

    private func toggleSelection(_ id: String) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FilterBuilderView(definition: .constant(.empty))
    }
    .environmentObject(AppState())
}
