import XCTest
@testable import AppCore

final class FilterDefinitionTests: XCTestCase {

    // MARK: - Empty Filter Tests

    func test_emptyFilter_hasDefaultValues() {
        let filter = FilterDefinition.empty

        XCTAssertNil(filter.includeProjectIds)
        XCTAssertNil(filter.includeSectionIds)
        XCTAssertNil(filter.includeTagIds)
        XCTAssertNil(filter.priorityAtLeast)
        XCTAssertNil(filter.priorityAtMost)
        XCTAssertNil(filter.stateIn)
        XCTAssertNil(filter.dueRange)
        XCTAssertNil(filter.includeRecurring)
        XCTAssertTrue(filter.excludeBlocked)
        XCTAssertTrue(filter.isEmpty)
    }

    func test_allFilter_includesBlocked() {
        let filter = FilterDefinition.all

        XCTAssertFalse(filter.excludeBlocked)
    }

    // MARK: - Convenience Builder Tests

    func test_projectFilter_createsCorrectly() {
        let filter = FilterDefinition.project("proj-1")

        XCTAssertEqual(filter.includeProjectIds, ["proj-1"])
        XCTAssertNil(filter.includeTagIds)
    }

    func test_tagFilter_createsCorrectly() {
        let filter = FilterDefinition.tag("tag-1")

        XCTAssertEqual(filter.includeTagIds, ["tag-1"])
        XCTAssertNil(filter.includeProjectIds)
    }

    func test_priorityFilter_createsCorrectly() {
        let filter = FilterDefinition.priorityAtLeast(.p2)

        XCTAssertEqual(filter.priorityAtLeast, .p2)
    }

    func test_dueRangeFilter_createsCorrectly() {
        let filter = FilterDefinition.due(.today)

        XCTAssertEqual(filter.dueRange, .today)
    }

    // MARK: - Combination Tests

    func test_combined_mergesProjectIds() {
        let filter1 = FilterDefinition(includeProjectIds: ["proj-1", "proj-2"])
        let filter2 = FilterDefinition(includeProjectIds: ["proj-2", "proj-3"])

        let combined = filter1.combined(with: filter2)

        // 교집합
        XCTAssertEqual(Set(combined.includeProjectIds ?? []), Set(["proj-2"]))
    }

    func test_combined_takesHigherPriority() {
        let filter1 = FilterDefinition(priorityAtLeast: .p3)
        let filter2 = FilterDefinition(priorityAtLeast: .p1)

        let combined = filter1.combined(with: filter2)

        // P1이 더 높음 (rawValue가 작음)
        XCTAssertEqual(combined.priorityAtLeast, .p1)
    }

    func test_combined_takesLowerPriorityForAtMost() {
        let filter1 = FilterDefinition(priorityAtMost: .p2)
        let filter2 = FilterDefinition(priorityAtMost: .p4)

        let combined = filter1.combined(with: filter2)

        // P4가 더 낮음 (rawValue가 큼)
        XCTAssertEqual(combined.priorityAtMost, .p4)
    }

    func test_combined_intersectsStates() {
        let filter1 = FilterDefinition(stateIn: [.todo, .doing])
        let filter2 = FilterDefinition(stateIn: [.doing, .done])

        let combined = filter1.combined(with: filter2)

        XCTAssertEqual(combined.stateIn, [.doing])
    }

    func test_combined_orsExcludeBlocked() {
        let filter1 = FilterDefinition(excludeBlocked: false)
        let filter2 = FilterDefinition(excludeBlocked: true)

        let combined = filter1.combined(with: filter2)

        XCTAssertTrue(combined.excludeBlocked)
    }

    // MARK: - DueRange Tests

    func test_dueRange_descriptionKR() {
        XCTAssertEqual(DueRange.today.descriptionKR, "오늘")
        XCTAssertEqual(DueRange.next7.descriptionKR, "7일 이내")
        XCTAssertEqual(DueRange.overdue.descriptionKR, "지연")
        XCTAssertEqual(DueRange.none.descriptionKR, "마감일 없음")
        XCTAssertEqual(DueRange.any.descriptionKR, "마감일 있음")
    }

    func test_dueRange_descriptionEN() {
        XCTAssertEqual(DueRange.today.descriptionEN, "Today")
        XCTAssertEqual(DueRange.next7.descriptionEN, "Next 7 days")
        XCTAssertEqual(DueRange.overdue.descriptionEN, "Overdue")
        XCTAssertEqual(DueRange.none.descriptionEN, "No due date")
        XCTAssertEqual(DueRange.any.descriptionEN, "Has due date")
    }

    // MARK: - Codable Tests

    func test_filterDefinition_roundTrip() throws {
        let original = FilterDefinition(
            includeProjectIds: ["proj-1"],
            includeTagIds: ["tag-1", "tag-2"],
            priorityAtLeast: .p2,
            stateIn: [.todo, .doing],
            dueRange: .next7,
            includeRecurring: true,
            excludeBlocked: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterDefinition.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - Summary Tests

    func test_summaryKR_emptyFilter() {
        let filter = FilterDefinition.empty
        XCTAssertEqual(filter.summaryKR, "전체")
    }

    func test_summaryKR_withConditions() {
        let filter = FilterDefinition(
            includeProjectIds: ["p1", "p2"],
            priorityAtLeast: .p1,
            dueRange: .today
        )

        let summary = filter.summaryKR
        XCTAssertTrue(summary.contains("프로젝트 2개"))
        XCTAssertTrue(summary.contains("P1 이상"))
        XCTAssertTrue(summary.contains("오늘"))
    }
}
