import XCTest
@testable import AppCore

/// WorkflowState 테스트
/// - data-model.md A4 준수: todo/doing/done, 기본값 todo
final class WorkflowStateTests: XCTestCase {

    // MARK: - Default Value

    func testDefaultState_IsTodo() {
        XCTAssertEqual(WorkflowState.defaultState, .todo)
    }

    // MARK: - Raw Values

    func testRawValues() {
        XCTAssertEqual(WorkflowState.todo.rawValue, "todo")
        XCTAssertEqual(WorkflowState.doing.rawValue, "doing")
        XCTAssertEqual(WorkflowState.done.rawValue, "done")
    }

    // MARK: - Convenience Properties

    func testIsCompleted() {
        XCTAssertFalse(WorkflowState.todo.isCompleted)
        XCTAssertFalse(WorkflowState.doing.isCompleted)
        XCTAssertTrue(WorkflowState.done.isCompleted)
    }

    func testIsActive() {
        XCTAssertTrue(WorkflowState.todo.isActive)
        XCTAssertTrue(WorkflowState.doing.isActive)
        XCTAssertFalse(WorkflowState.done.isActive)
    }

    func testIsInProgress() {
        XCTAssertFalse(WorkflowState.todo.isInProgress)
        XCTAssertTrue(WorkflowState.doing.isInProgress)
        XCTAssertFalse(WorkflowState.done.isInProgress)
    }

    // MARK: - Board Order

    func testBoardOrder() {
        XCTAssertEqual(WorkflowState.todo.boardOrder, 0)
        XCTAssertEqual(WorkflowState.doing.boardOrder, 1)
        XCTAssertEqual(WorkflowState.done.boardOrder, 2)
    }

    func testBoardOrdered() {
        let ordered = WorkflowState.boardOrdered
        XCTAssertEqual(ordered, [.todo, .doing, .done])
    }

    // MARK: - Codable

    func testCodable_RoundTrip() throws {
        for state in WorkflowState.allCases {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(WorkflowState.self, from: data)
            XCTAssertEqual(decoded, state)
        }
    }

    func testCodable_JSONFormat() throws {
        let state = WorkflowState.doing
        let data = try JSONEncoder().encode(state)
        let json = String(data: data, encoding: .utf8)

        XCTAssertEqual(json, "\"doing\"")
    }

    // MARK: - Descriptions

    func testDescriptionKR() {
        XCTAssertEqual(WorkflowState.todo.descriptionKR, "할 일")
        XCTAssertEqual(WorkflowState.doing.descriptionKR, "진행 중")
        XCTAssertEqual(WorkflowState.done.descriptionKR, "완료")
    }

    func testDescriptionEN() {
        XCTAssertEqual(WorkflowState.todo.descriptionEN, "To Do")
        XCTAssertEqual(WorkflowState.doing.descriptionEN, "In Progress")
        XCTAssertEqual(WorkflowState.done.descriptionEN, "Done")
    }

    // MARK: - CaseIterable

    func testCaseIterable_Count() {
        XCTAssertEqual(WorkflowState.allCases.count, 3)
    }
}
