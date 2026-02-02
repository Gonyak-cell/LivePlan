import Foundation

/// Built-in 필터 정의
/// - product-decisions.md 4.1 준수
/// - 6개 기본 필터: Today, Upcoming, Overdue, P1, ByTag, ByProject
public enum BuiltInFilters {

    // MARK: - Filter IDs

    /// Built-in 필터 ID
    public enum FilterId: String, CaseIterable, Sendable {
        case today = "builtin-today"
        case upcoming = "builtin-upcoming"
        case overdue = "builtin-overdue"
        case highPriority = "builtin-p1"
        case byTag = "builtin-by-tag"
        case byProject = "builtin-by-project"
    }

    // MARK: - Today Filter

    /// 오늘 마감 필터
    public static let today = SavedView.builtIn(
        id: FilterId.today.rawValue,
        name: "오늘",
        definition: FilterDefinition(
            dueRange: .today,
            excludeBlocked: true
        ),
        sortOrder: 0
    )

    /// Today 필터 (EN)
    public static let todayEN = SavedView.builtIn(
        id: FilterId.today.rawValue,
        name: "Today",
        definition: FilterDefinition(
            dueRange: .today,
            excludeBlocked: true
        ),
        sortOrder: 0
    )

    // MARK: - Upcoming Filter

    /// 다가오는 7일 필터
    public static let upcoming = SavedView.builtIn(
        id: FilterId.upcoming.rawValue,
        name: "다가오는 7일",
        definition: FilterDefinition(
            dueRange: .next7,
            excludeBlocked: true
        ),
        sortOrder: 1
    )

    /// Upcoming 필터 (EN)
    public static let upcomingEN = SavedView.builtIn(
        id: FilterId.upcoming.rawValue,
        name: "Next 7 days",
        definition: FilterDefinition(
            dueRange: .next7,
            excludeBlocked: true
        ),
        sortOrder: 1
    )

    // MARK: - Overdue Filter

    /// 지연 필터
    public static let overdue = SavedView.builtIn(
        id: FilterId.overdue.rawValue,
        name: "지연",
        definition: FilterDefinition(
            dueRange: .overdue,
            excludeBlocked: false // 지연은 blocked도 표시
        ),
        sortOrder: 2
    )

    /// Overdue 필터 (EN)
    public static let overdueEN = SavedView.builtIn(
        id: FilterId.overdue.rawValue,
        name: "Overdue",
        definition: FilterDefinition(
            dueRange: .overdue,
            excludeBlocked: false
        ),
        sortOrder: 2
    )

    // MARK: - High Priority Filter

    /// P1 우선순위 필터
    public static let highPriority = SavedView.builtIn(
        id: FilterId.highPriority.rawValue,
        name: "중요 (P1)",
        definition: FilterDefinition(
            priorityAtLeast: .p1,
            priorityAtMost: .p1,
            excludeBlocked: true
        ),
        sortOrder: 3
    )

    /// High Priority 필터 (EN)
    public static let highPriorityEN = SavedView.builtIn(
        id: FilterId.highPriority.rawValue,
        name: "Priority 1",
        definition: FilterDefinition(
            priorityAtLeast: .p1,
            priorityAtMost: .p1,
            excludeBlocked: true
        ),
        sortOrder: 3
    )

    // MARK: - All Built-in Filters

    /// 모든 Built-in 필터 (KR)
    public static var allKR: [SavedView] {
        [today, upcoming, overdue, highPriority]
    }

    /// 모든 Built-in 필터 (EN)
    public static var allEN: [SavedView] {
        [todayEN, upcomingEN, overdueEN, highPriorityEN]
    }

    /// 현재 로케일에 맞는 Built-in 필터
    public static var all: [SavedView] {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return languageCode == "ko" ? allKR : allEN
    }

    // MARK: - Dynamic Filters

    /// 특정 태그 기반 필터 생성
    public static func byTag(tagId: String, tagName: String) -> SavedView {
        SavedView.builtIn(
            id: "\(FilterId.byTag.rawValue)-\(tagId)",
            name: "#\(tagName)",
            definition: FilterDefinition(
                includeTagIds: [tagId],
                excludeBlocked: true
            ),
            sortOrder: 100 // 커스텀 필터보다 뒤에
        )
    }

    /// 특정 프로젝트 기반 필터 생성
    public static func byProject(projectId: String, projectName: String) -> SavedView {
        SavedView.builtIn(
            id: "\(FilterId.byProject.rawValue)-\(projectId)",
            name: "@\(projectName)",
            definition: FilterDefinition(
                includeProjectIds: [projectId],
                excludeBlocked: true
            ),
            sortOrder: 101
        )
    }

    // MARK: - Custom Filter Templates

    /// 커스텀 필터 템플릿
    public enum Template: String, CaseIterable, Sendable {
        case activeTasks
        case recurringOnly
        case noDate
        case inProgress

        /// 템플릿에 해당하는 FilterDefinition
        public var definition: FilterDefinition {
            switch self {
            case .activeTasks:
                return FilterDefinition(
                    stateIn: [.todo, .doing],
                    excludeBlocked: true
                )
            case .recurringOnly:
                return FilterDefinition(
                    includeRecurring: true,
                    excludeBlocked: true
                )
            case .noDate:
                return FilterDefinition(
                    dueRange: .none,
                    excludeBlocked: true
                )
            case .inProgress:
                return FilterDefinition(
                    stateIn: [.doing],
                    excludeBlocked: false
                )
            }
        }

        /// 템플릿 이름 (KR)
        public var nameKR: String {
            switch self {
            case .activeTasks: return "활성 태스크"
            case .recurringOnly: return "반복만"
            case .noDate: return "마감일 없음"
            case .inProgress: return "진행 중"
            }
        }

        /// 템플릿 이름 (EN)
        public var nameEN: String {
            switch self {
            case .activeTasks: return "Active Tasks"
            case .recurringOnly: return "Recurring Only"
            case .noDate: return "No Due Date"
            case .inProgress: return "In Progress"
            }
        }
    }
}

// MARK: - Convenience

extension BuiltInFilters {
    /// Built-in 필터 ID인지 확인
    public static func isBuiltIn(id: String) -> Bool {
        FilterId.allCases.contains { $0.rawValue == id } ||
        id.hasPrefix(FilterId.byTag.rawValue) ||
        id.hasPrefix(FilterId.byProject.rawValue)
    }

    /// ID로 Built-in 필터 가져오기
    public static func filter(for id: FilterId) -> SavedView? {
        switch id {
        case .today: return today
        case .upcoming: return upcoming
        case .overdue: return overdue
        case .highPriority: return highPriority
        case .byTag, .byProject: return nil // 동적 필터는 nil
        }
    }
}
