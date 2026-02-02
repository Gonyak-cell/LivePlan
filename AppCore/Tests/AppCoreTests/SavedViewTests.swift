import XCTest
@testable import AppCore

final class SavedViewTests: XCTestCase {

    // MARK: - Creation Tests

    func test_customSavedView_createdCorrectly() {
        let definition = FilterDefinition.project("proj-1")
        let view = SavedView.custom(
            name: "My Filter",
            definition: definition
        )

        XCTAssertEqual(view.name, "My Filter")
        XCTAssertFalse(view.isBuiltIn)
        XCTAssertEqual(view.scope, .global)
        XCTAssertEqual(view.viewType, .list)
    }

    func test_builtInSavedView_createdCorrectly() {
        let view = SavedView.builtIn(
            id: "test-builtin",
            name: "Test",
            definition: .empty,
            sortOrder: 5
        )

        XCTAssertEqual(view.id, "test-builtin")
        XCTAssertTrue(view.isBuiltIn)
        XCTAssertEqual(view.sortOrder, 5)
    }

    // MARK: - ViewScope Tests

    func test_globalScope_isGlobal() {
        let scope = ViewScope.global

        XCTAssertTrue(scope.isGlobal)
        XCTAssertNil(scope.projectId)
    }

    func test_projectScope_hasProjectId() {
        let scope = ViewScope.project("proj-1")

        XCTAssertFalse(scope.isGlobal)
        XCTAssertEqual(scope.projectId, "proj-1")
    }

    // MARK: - Sorting Tests

    func test_builtIn_sortsBeforeCustom() {
        let builtIn = SavedView.builtIn(
            id: "builtin",
            name: "Built-in",
            definition: .empty,
            sortOrder: 10
        )
        let custom = SavedView.custom(
            name: "Custom",
            definition: .empty
        )

        XCTAssertTrue(builtIn < custom)
    }

    func test_sameCategorySort_byOrder() {
        let first = SavedView.builtIn(
            id: "first",
            name: "First",
            definition: .empty,
            sortOrder: 1
        )
        let second = SavedView.builtIn(
            id: "second",
            name: "Second",
            definition: .empty,
            sortOrder: 2
        )

        XCTAssertTrue(first < second)
    }

    // MARK: - Codable Tests

    func test_savedView_roundTrip() throws {
        let original = SavedView(
            id: "test",
            name: "Test View",
            scope: .project("proj-1"),
            viewType: .board,
            definition: FilterDefinition(
                includeProjectIds: ["proj-1"],
                priorityAtLeast: .p2
            ),
            isBuiltIn: false,
            sortOrder: 5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SavedView.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.scope, decoded.scope)
        XCTAssertEqual(original.viewType, decoded.viewType)
        XCTAssertEqual(original.definition, decoded.definition)
        XCTAssertEqual(original.isBuiltIn, decoded.isBuiltIn)
        XCTAssertEqual(original.sortOrder, decoded.sortOrder)
    }

    func test_viewScope_roundTrip_global() throws {
        let original = ViewScope.global

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ViewScope.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func test_viewScope_roundTrip_project() throws {
        let original = ViewScope.project("proj-123")

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ViewScope.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - Built-in Filters Tests

    func test_builtInFilters_todayExists() {
        let today = BuiltInFilters.today

        XCTAssertEqual(today.id, BuiltInFilters.FilterId.today.rawValue)
        XCTAssertTrue(today.isBuiltIn)
        XCTAssertEqual(today.definition.dueRange, .today)
    }

    func test_builtInFilters_upcomingExists() {
        let upcoming = BuiltInFilters.upcoming

        XCTAssertEqual(upcoming.definition.dueRange, .next7)
    }

    func test_builtInFilters_overdueExists() {
        let overdue = BuiltInFilters.overdue

        XCTAssertEqual(overdue.definition.dueRange, .overdue)
        XCTAssertFalse(overdue.definition.excludeBlocked) // 지연은 blocked도 포함
    }

    func test_builtInFilters_highPriorityExists() {
        let p1 = BuiltInFilters.highPriority

        XCTAssertEqual(p1.definition.priorityAtLeast, .p1)
        XCTAssertEqual(p1.definition.priorityAtMost, .p1)
    }

    func test_builtInFilters_byTagCreation() {
        let tagFilter = BuiltInFilters.byTag(tagId: "tag-1", tagName: "work")

        XCTAssertEqual(tagFilter.name, "#work")
        XCTAssertEqual(tagFilter.definition.includeTagIds, ["tag-1"])
    }

    func test_builtInFilters_byProjectCreation() {
        let projectFilter = BuiltInFilters.byProject(projectId: "proj-1", projectName: "Work")

        XCTAssertEqual(projectFilter.name, "@Work")
        XCTAssertEqual(projectFilter.definition.includeProjectIds, ["proj-1"])
    }

    func test_builtInFilters_isBuiltIn() {
        XCTAssertTrue(BuiltInFilters.isBuiltIn(id: "builtin-today"))
        XCTAssertTrue(BuiltInFilters.isBuiltIn(id: "builtin-by-tag-123"))
        XCTAssertFalse(BuiltInFilters.isBuiltIn(id: "custom-filter"))
    }

    func test_builtInFilters_allKR_has4Filters() {
        let all = BuiltInFilters.allKR

        XCTAssertEqual(all.count, 4)
    }

    // MARK: - Template Tests

    func test_template_activeTasks() {
        let template = BuiltInFilters.Template.activeTasks

        XCTAssertEqual(template.definition.stateIn, [.todo, .doing])
        XCTAssertTrue(template.definition.excludeBlocked)
    }

    func test_template_recurringOnly() {
        let template = BuiltInFilters.Template.recurringOnly

        XCTAssertEqual(template.definition.includeRecurring, true)
    }

    func test_template_noDate() {
        let template = BuiltInFilters.Template.noDate

        XCTAssertEqual(template.definition.dueRange, .none)
    }

    func test_template_inProgress() {
        let template = BuiltInFilters.Template.inProgress

        XCTAssertEqual(template.definition.stateIn, [.doing])
    }
}
