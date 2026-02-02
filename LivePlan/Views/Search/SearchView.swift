import SwiftUI
import AppCore

/// 검색 뷰
/// - P2-M4-08: LocalSearchEngine 기반 검색
/// - 프로젝트/태스크/태그/섹션 통합 검색
struct SearchView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var searchResults: LocalSearchEngine.SearchResults = .empty
    @State private var isSearching = false

    private let searchEngine = LocalSearchEngine()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 검색 바
                searchBar

                // 결과 영역
                if searchText.isEmpty {
                    emptySearchState
                } else if searchResults.isEmpty && !isSearching {
                    noResultsState
                } else {
                    searchResultsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("검색")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("프로젝트, 할 일, 태그 검색", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = .empty
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .onChange(of: searchText) { _, newValue in
            performSearch()
        }
    }

    // MARK: - States

    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("검색어를 입력하세요")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("프로젝트, 할 일, 태그, 섹션을 검색할 수 있습니다")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    private var noResultsState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("검색 결과가 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("'\(searchText)'에 대한 결과를 찾을 수 없습니다")
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding()
    }

    // MARK: - Results List

    private var searchResultsList: some View {
        List {
            // 프로젝트 결과
            if !searchResults.projects.isEmpty {
                Section("프로젝트") {
                    ForEach(searchResults.projects) { result in
                        NavigationLink {
                            if let project = appState.projects.first(where: { $0.id == result.id }) {
                                ProjectDetailView(project: project)
                            }
                        } label: {
                            SearchResultRow(result: result, iconName: "folder.fill", iconColor: .blue)
                        }
                    }
                }
            }

            // 태스크 결과
            if !searchResults.tasks.isEmpty {
                Section("할 일") {
                    ForEach(searchResults.tasks) { result in
                        NavigationLink {
                            if let task = appState.tasks.first(where: { $0.id == result.id }) {
                                TaskDetailView(task: task)
                            }
                        } label: {
                            SearchResultRow(result: result, iconName: "checkmark.circle", iconColor: .green)
                        }
                    }
                }
            }

            // 태그 결과
            if !searchResults.tags.isEmpty {
                Section("태그") {
                    ForEach(searchResults.tags) { result in
                        NavigationLink {
                            if let tag = appState.tags.first(where: { $0.id == result.id }) {
                                // 해당 태그가 포함된 태스크 필터 화면으로 이동
                                FilterDetailView(savedView: BuiltInFilters.byTag(tagId: tag.id, tagName: tag.name))
                            }
                        } label: {
                            SearchResultRow(result: result, iconName: "tag.fill", iconColor: .orange)
                        }
                    }
                }
            }

            // 섹션 결과
            if !searchResults.sections.isEmpty {
                Section("섹션") {
                    ForEach(searchResults.sections) { result in
                        NavigationLink {
                            if let section = appState.sections.first(where: { $0.id == result.id }),
                               let project = appState.projects.first(where: { $0.id == section.projectId }) {
                                ProjectDetailView(project: project)
                            }
                        } label: {
                            SearchResultRow(result: result, iconName: "rectangle.3.group", iconColor: .purple)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Search Logic

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = .empty
            return
        }

        isSearching = true

        searchResults = searchEngine.search(
            query: query,
            projects: appState.projects,
            tasks: appState.tasks,
            tags: appState.tags,
            sections: appState.sections,
            options: .default
        )

        isSearching = false
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: LocalSearchEngine.SearchResult
    let iconName: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                // 하이라이트된 제목
                highlightedTitle

                // 서브타이틀
                if let subtitle = result.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var highlightedTitle: some View {
        if result.matchRanges.isEmpty {
            Text(result.title)
                .font(.subheadline)
        } else {
            // 매치 범위 하이라이트
            Text(attributedTitle)
                .font(.subheadline)
        }
    }

    private var attributedTitle: AttributedString {
        var attributed = AttributedString(result.title)

        for range in result.matchRanges {
            // String.Index를 AttributedString.Index로 변환
            let startOffset = result.title.distance(from: result.title.startIndex, to: range.lowerBound)
            let endOffset = result.title.distance(from: result.title.startIndex, to: range.upperBound)

            if let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset),
               let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset) {
                attributed[attrStart..<attrEnd].backgroundColor = .yellow.opacity(0.3)
                attributed[attrStart..<attrEnd].font = .subheadline.bold()
            }
        }

        return attributed
    }
}

// MARK: - Preview

#Preview {
    SearchView()
        .environmentObject(AppState())
}
