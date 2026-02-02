import Foundation

/// 로컬 검색 엔진
/// - data-model.md / product-decisions.md 4.2 준수
/// - 프로젝트/태스크/태그 제목 검색
/// - 대소문자 무시, 인덱싱/서버 검색 금지
public struct LocalSearchEngine: Sendable {

    // MARK: - Search Result Types

    /// 검색 결과 타입
    public enum ResultType: String, Codable, Sendable {
        case project
        case task
        case tag
        case section
    }

    /// 단일 검색 결과
    public struct SearchResult: Identifiable, Equatable, Sendable {
        public let id: String
        public let type: ResultType
        public let title: String
        public let subtitle: String?
        public let matchRanges: [Range<String.Index>]

        public init(
            id: String,
            type: ResultType,
            title: String,
            subtitle: String? = nil,
            matchRanges: [Range<String.Index>] = []
        ) {
            self.id = id
            self.type = type
            self.title = title
            self.subtitle = subtitle
            self.matchRanges = matchRanges
        }
    }

    /// 검색 결과 집합
    public struct SearchResults: Equatable, Sendable {
        public let query: String
        public let projects: [SearchResult]
        public let tasks: [SearchResult]
        public let tags: [SearchResult]
        public let sections: [SearchResult]

        public var isEmpty: Bool {
            projects.isEmpty && tasks.isEmpty && tags.isEmpty && sections.isEmpty
        }

        public var totalCount: Int {
            projects.count + tasks.count + tags.count + sections.count
        }

        public static let empty = SearchResults(
            query: "",
            projects: [],
            tasks: [],
            tags: [],
            sections: []
        )
    }

    // MARK: - Search Options

    /// 검색 옵션
    public struct SearchOptions: Sendable {
        /// 검색 대상 타입
        public var searchIn: Set<ResultType>

        /// 최대 결과 수 (타입별)
        public var maxResultsPerType: Int

        /// 노트도 검색할지 여부
        public var includeNotes: Bool

        public init(
            searchIn: Set<ResultType> = [.project, .task, .tag, .section],
            maxResultsPerType: Int = 20,
            includeNotes: Bool = true
        ) {
            self.searchIn = searchIn
            self.maxResultsPerType = maxResultsPerType
            self.includeNotes = includeNotes
        }

        public static let `default` = SearchOptions()
        public static let tasksOnly = SearchOptions(searchIn: [.task])
        public static let projectsOnly = SearchOptions(searchIn: [.project])
    }

    // MARK: - Initializer

    public init() {}

    // MARK: - Search

    /// 전체 검색
    /// - Parameters:
    ///   - query: 검색어
    ///   - projects: 프로젝트 목록
    ///   - tasks: 태스크 목록
    ///   - tags: 태그 목록
    ///   - sections: 섹션 목록
    ///   - options: 검색 옵션
    /// - Returns: 검색 결과
    public func search(
        query: String,
        projects: [Project],
        tasks: [Task],
        tags: [Tag],
        sections: [Section],
        options: SearchOptions = .default
    ) -> SearchResults {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return .empty
        }

        let normalizedQuery = trimmedQuery.lowercased()

        var projectResults: [SearchResult] = []
        var taskResults: [SearchResult] = []
        var tagResults: [SearchResult] = []
        var sectionResults: [SearchResult] = []

        // 프로젝트 검색
        if options.searchIn.contains(.project) {
            projectResults = searchProjects(
                query: normalizedQuery,
                projects: projects,
                options: options
            )
        }

        // 태스크 검색
        if options.searchIn.contains(.task) {
            taskResults = searchTasks(
                query: normalizedQuery,
                tasks: tasks,
                projects: projects,
                options: options
            )
        }

        // 태그 검색
        if options.searchIn.contains(.tag) {
            tagResults = searchTags(
                query: normalizedQuery,
                tags: tags,
                options: options
            )
        }

        // 섹션 검색
        if options.searchIn.contains(.section) {
            sectionResults = searchSections(
                query: normalizedQuery,
                sections: sections,
                projects: projects,
                options: options
            )
        }

        return SearchResults(
            query: trimmedQuery,
            projects: projectResults,
            tasks: taskResults,
            tags: tagResults,
            sections: sectionResults
        )
    }

    // MARK: - Private Search Methods

    private func searchProjects(
        query: String,
        projects: [Project],
        options: SearchOptions
    ) -> [SearchResult] {
        var results: [SearchResult] = []

        for project in projects {
            let titleLower = project.title.lowercased()

            if titleLower.contains(query) {
                let ranges = findMatchRanges(in: project.title, query: query)
                results.append(SearchResult(
                    id: project.id,
                    type: .project,
                    title: project.title,
                    subtitle: project.status.descriptionKR,
                    matchRanges: ranges
                ))
            } else if options.includeNotes,
                      let note = project.note,
                      note.lowercased().contains(query) {
                results.append(SearchResult(
                    id: project.id,
                    type: .project,
                    title: project.title,
                    subtitle: "노트에서 발견",
                    matchRanges: []
                ))
            }

            if results.count >= options.maxResultsPerType {
                break
            }
        }

        return results
    }

    private func searchTasks(
        query: String,
        tasks: [Task],
        projects: [Project],
        options: SearchOptions
    ) -> [SearchResult] {
        var results: [SearchResult] = []
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })

        for task in tasks {
            let titleLower = task.title.lowercased()

            if titleLower.contains(query) {
                let ranges = findMatchRanges(in: task.title, query: query)
                let projectName = projectMap[task.projectId]?.title
                results.append(SearchResult(
                    id: task.id,
                    type: .task,
                    title: task.title,
                    subtitle: projectName,
                    matchRanges: ranges
                ))
            } else if options.includeNotes,
                      let note = task.note,
                      note.lowercased().contains(query) {
                let projectName = projectMap[task.projectId]?.title
                results.append(SearchResult(
                    id: task.id,
                    type: .task,
                    title: task.title,
                    subtitle: projectName.map { "\($0) · 노트에서 발견" } ?? "노트에서 발견",
                    matchRanges: []
                ))
            }

            if results.count >= options.maxResultsPerType {
                break
            }
        }

        return results
    }

    private func searchTags(
        query: String,
        tags: [Tag],
        options: SearchOptions
    ) -> [SearchResult] {
        var results: [SearchResult] = []

        for tag in tags {
            let nameLower = tag.name.lowercased()

            if nameLower.contains(query) {
                let ranges = findMatchRanges(in: tag.name, query: query)
                results.append(SearchResult(
                    id: tag.id,
                    type: .tag,
                    title: tag.name,
                    subtitle: nil,
                    matchRanges: ranges
                ))
            }

            if results.count >= options.maxResultsPerType {
                break
            }
        }

        return results
    }

    private func searchSections(
        query: String,
        sections: [Section],
        projects: [Project],
        options: SearchOptions
    ) -> [SearchResult] {
        var results: [SearchResult] = []
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })

        for section in sections {
            let titleLower = section.title.lowercased()

            if titleLower.contains(query) {
                let ranges = findMatchRanges(in: section.title, query: query)
                let projectName = projectMap[section.projectId]?.title
                results.append(SearchResult(
                    id: section.id,
                    type: .section,
                    title: section.title,
                    subtitle: projectName,
                    matchRanges: ranges
                ))
            }

            if results.count >= options.maxResultsPerType {
                break
            }
        }

        return results
    }

    // MARK: - Helpers

    private func findMatchRanges(in text: String, query: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStart = text.startIndex
        let textLower = text.lowercased()

        while searchStart < text.endIndex {
            if let range = textLower.range(of: query, range: searchStart..<text.endIndex) {
                // 원본 텍스트의 범위로 변환
                let originalRange = Range(
                    uncheckedBounds: (
                        lower: text.index(text.startIndex, offsetBy: textLower.distance(from: textLower.startIndex, to: range.lowerBound)),
                        upper: text.index(text.startIndex, offsetBy: textLower.distance(from: textLower.startIndex, to: range.upperBound))
                    )
                )
                ranges.append(originalRange)
                searchStart = range.upperBound
            } else {
                break
            }
        }

        return ranges
    }
}

// MARK: - Quick Search

extension LocalSearchEngine {
    /// 빠른 검색 (태스크만, 결과 5개)
    public func quickSearch(
        query: String,
        tasks: [Task],
        projects: [Project]
    ) -> [SearchResult] {
        let options = SearchOptions(
            searchIn: [.task],
            maxResultsPerType: 5,
            includeNotes: false
        )
        return search(
            query: query,
            projects: projects,
            tasks: tasks,
            tags: [],
            sections: [],
            options: options
        ).tasks
    }
}
