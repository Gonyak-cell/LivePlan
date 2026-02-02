import XCTest
@testable import AppCore

/// Task 테스트
/// - data-model.md A4 준수
/// - Phase 2 확장 필드 포함
final class TaskTests: XCTestCase {

    // MARK: - Creation (Phase 1 Compatible)

    func testTask_BasicCreation() {
        let task = Task(projectId: "p1", title: "Test Task")

        XCTAssertFalse(task.id.isEmpty)
        XCTAssertEqual(task.projectId, "p1")
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.taskType, .oneOff)
        XCTAssertNil(task.dueDate)
    }

    func testTask_Phase2Defaults() {
        let task = Task(projectId: "p1", title: "Test")

        // Phase 2 기본값 확인
        XCTAssertNil(task.sectionId)
        XCTAssertTrue(task.tagIds.isEmpty)
        XCTAssertEqual(task.priority, .p4) // defaultPriority
        XCTAssertEqual(task.workflowState, .todo) // defaultState
        XCTAssertNil(task.startAt)
        XCTAssertNil(task.note)
        XCTAssertTrue(task.blockedByTaskIds.isEmpty)
        XCTAssertNil(task.recurrenceRule)
        XCTAssertNil(task.recurrenceBehavior)
        XCTAssertNil(task.nextOccurrenceDueAt)
    }

    // MARK: - Recurrence

    func testIsRecurring_DailyRecurring() {
        let task = Task(projectId: "p1", title: "Daily", taskType: .dailyRecurring)

        XCTAssertTrue(task.isRecurring)
        XCTAssertFalse(task.isOneOff)
    }

    func testIsRecurring_WithRecurrenceRule() {
        let task = Task(
            projectId: "p1",
            title: "Weekly",
            recurrenceRule: .weekly(weekdays: [.monday])
        )

        XCTAssertTrue(task.isRecurring)
    }

    func testIsRecurring_OneOff() {
        let task = Task(projectId: "p1", title: "One-off")

        XCTAssertFalse(task.isRecurring)
        XCTAssertTrue(task.isOneOff)
    }

    // MARK: - Recurrence Behavior

    func testEffectiveRecurrenceBehavior_DailyRecurring() {
        let task = Task(projectId: "p1", title: "Daily", taskType: .dailyRecurring)

        XCTAssertEqual(task.effectiveRecurrenceBehavior, .habitReset)
        XCTAssertTrue(task.isHabitReset)
        XCTAssertFalse(task.isRollover)
    }

    func testEffectiveRecurrenceBehavior_RecurrenceRule() {
        let task = Task(
            projectId: "p1",
            title: "Weekly",
            recurrenceRule: .weekly(weekdays: [.monday])
        )

        XCTAssertEqual(task.effectiveRecurrenceBehavior, .rollover)
        XCTAssertTrue(task.isRollover)
        XCTAssertFalse(task.isHabitReset)
    }

    func testEffectiveRecurrenceBehavior_ExplicitOverride() {
        let task = Task(
            projectId: "p1",
            title: "Weekly Habit",
            recurrenceRule: .weekly(weekdays: [.monday]),
            recurrenceBehavior: .habitReset // 명시적 오버라이드
        )

        XCTAssertEqual(task.effectiveRecurrenceBehavior, .habitReset)
    }

    func testEffectiveRecurrenceBehavior_OneOff() {
        let task = Task(projectId: "p1", title: "One-off")

        XCTAssertNil(task.effectiveRecurrenceBehavior)
    }

    // MARK: - Due Date

    func testEffectiveDueDate_Regular() {
        let dueDate = Date()
        let task = Task(projectId: "p1", title: "Task", dueDate: dueDate)

        XCTAssertEqual(task.effectiveDueDate, dueDate)
    }

    func testEffectiveDueDate_Rollover() {
        let dueDate = Date()
        let nextDue = Date().addingTimeInterval(86400 * 7) // 7 days later

        let task = Task(
            projectId: "p1",
            title: "Weekly",
            dueDate: dueDate,
            recurrenceRule: .weekly(weekdays: [.monday]),
            nextOccurrenceDueAt: nextDue
        )

        XCTAssertEqual(task.effectiveDueDate, nextDue)
    }

    // MARK: - Dependencies

    func testIsBlocked() {
        let blockedTask = Task(
            projectId: "p1",
            title: "Blocked",
            blockedByTaskIds: ["t1", "t2"]
        )
        let unblockedTask = Task(projectId: "p1", title: "Unblocked")

        XCTAssertTrue(blockedTask.isBlocked)
        XCTAssertFalse(unblockedTask.isBlocked)
    }

    func testIsBlockedBy() {
        let task = Task(
            projectId: "p1",
            title: "Task",
            blockedByTaskIds: ["t1", "t2"]
        )

        XCTAssertTrue(task.isBlockedBy("t1"))
        XCTAssertTrue(task.isBlockedBy("t2"))
        XCTAssertFalse(task.isBlockedBy("t3"))
    }

    // MARK: - Workflow State

    func testWorkflowState_Convenience() {
        let todoTask = Task(projectId: "p1", title: "Todo", workflowState: .todo)
        let doingTask = Task(projectId: "p1", title: "Doing", workflowState: .doing)
        let doneTask = Task(projectId: "p1", title: "Done", workflowState: .done)

        XCTAssertFalse(todoTask.isDone)
        XCTAssertFalse(todoTask.isInProgress)
        XCTAssertTrue(todoTask.isActive)

        XCTAssertFalse(doingTask.isDone)
        XCTAssertTrue(doingTask.isInProgress)
        XCTAssertTrue(doingTask.isActive)

        XCTAssertTrue(doneTask.isDone)
        XCTAssertFalse(doneTask.isInProgress)
        XCTAssertFalse(doneTask.isActive)
    }

    // MARK: - Tags

    func testTags_Convenience() {
        let taggedTask = Task(projectId: "p1", title: "Tagged", tagIds: ["tag1", "tag2"])
        let untaggedTask = Task(projectId: "p1", title: "Untagged")

        XCTAssertTrue(taggedTask.hasTags)
        XCTAssertTrue(taggedTask.hasTag("tag1"))
        XCTAssertFalse(taggedTask.hasTag("tag3"))

        XCTAssertFalse(untaggedTask.hasTags)
    }

    // MARK: - Validation

    func testValidation_Valid() {
        let task = Task(projectId: "p1", title: "Valid Task")

        XCTAssertTrue(task.isValid)
        XCTAssertNil(task.validate())
    }

    func testValidation_SelfReference() {
        let task = Task(
            id: "task-1",
            projectId: "p1",
            title: "Self Ref",
            blockedByTaskIds: ["task-1"] // 자기 자신 참조
        )

        XCTAssertFalse(task.isValid)
        XCTAssertEqual(task.validate(), .selfReference)
    }

    func testValidation_InvalidRecurrenceRule() {
        let task = Task(
            projectId: "p1",
            title: "Invalid Weekly",
            recurrenceRule: RecurrenceRule(kind: .weekly, weekdays: []) // 빈 weekdays
        )

        XCTAssertFalse(task.isValid)
        if case .invalidRecurrenceRule(let error) = task.validate() {
            XCTAssertEqual(error, .weeklyWithoutWeekdays)
        } else {
            XCTFail("Expected invalidRecurrenceRule error")
        }
    }

    // MARK: - Codable (Migration)

    func testCodable_RoundTrip_Full() throws {
        let task = Task(
            id: "t1",
            projectId: "p1",
            title: "Full Task",
            taskType: .oneOff,
            dueDate: Date(),
            sectionId: "s1",
            tagIds: ["tag1", "tag2"],
            priority: .p2,
            workflowState: .doing,
            note: "Some notes",
            blockedByTaskIds: ["t0"],
            recurrenceRule: .daily()
        )

        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(Task.self, from: data)

        XCTAssertEqual(decoded.id, task.id)
        XCTAssertEqual(decoded.projectId, task.projectId)
        XCTAssertEqual(decoded.title, task.title)
        XCTAssertEqual(decoded.sectionId, task.sectionId)
        XCTAssertEqual(decoded.tagIds, task.tagIds)
        XCTAssertEqual(decoded.priority, task.priority)
        XCTAssertEqual(decoded.workflowState, task.workflowState)
        XCTAssertEqual(decoded.note, task.note)
        XCTAssertEqual(decoded.blockedByTaskIds, task.blockedByTaskIds)
        XCTAssertNotNil(decoded.recurrenceRule)
    }

    func testCodable_Phase1DataMigration() throws {
        // Phase 1 형식 JSON (새 필드 없음)
        let phase1JSON = """
        {
            "id": "t1",
            "projectId": "p1",
            "title": "Old Task",
            "taskType": "oneOff",
            "createdAt": 0,
            "updatedAt": 0
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Task.self, from: phase1JSON)

        // Phase 2 기본값 적용 확인
        XCTAssertEqual(decoded.id, "t1")
        XCTAssertEqual(decoded.title, "Old Task")
        XCTAssertTrue(decoded.tagIds.isEmpty)
        XCTAssertEqual(decoded.priority, .p4)
        XCTAssertEqual(decoded.workflowState, .todo)
        XCTAssertTrue(decoded.blockedByTaskIds.isEmpty)
    }

    // MARK: - Priority

    func testPriority_Sorting() {
        let tasks = [
            Task(projectId: "p1", title: "P4", priority: .p4),
            Task(projectId: "p1", title: "P1", priority: .p1),
            Task(projectId: "p1", title: "P3", priority: .p3),
            Task(projectId: "p1", title: "P2", priority: .p2)
        ]

        let sorted = tasks.sorted { $0.priority < $1.priority }

        XCTAssertEqual(sorted.map(\.title), ["P1", "P2", "P3", "P4"])
    }
}
