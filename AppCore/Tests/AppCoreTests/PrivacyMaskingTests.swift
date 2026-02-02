import XCTest
@testable import AppCore

/// 프라이버시 마스킹 테스트
/// - testing.md B7 준수
final class PrivacyMaskingTests: XCTestCase {

    private var computer: OutstandingComputer!
    private var masker: PrivacyMasker!

    override func setUp() {
        super.setUp()
        computer = OutstandingComputer()
        masker = PrivacyMasker()
    }

    // MARK: - B7: privacyMode에 따른 출력 규칙

    func testB7_Level0_Visible_ShowsOriginalTitle() {
        // Given
        let project = Project(id: "p1", title: "My Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Buy groceries", taskType: .oneOff)

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .visible,
            projects: [project],
            tasks: [task],
            completionLogs: []
        )

        // Then: 원문 표시
        XCTAssertEqual(summary.displayList.first?.displayTitle, "Buy groceries")
    }

    func testB7_Level1_Masked_ShowsAnonymized() {
        // Given
        let project = Project(id: "p1", title: "My Project", startDate: Date())
        let tasks = [
            Task(id: "t1", projectId: "p1", title: "Buy groceries", taskType: .oneOff),
            Task(id: "t2", projectId: "p1", title: "Call mom", taskType: .oneOff),
            Task(id: "t3", projectId: "p1", title: "Finish report", taskType: .oneOff)
        ]

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .masked,
            projects: [project],
            tasks: tasks,
            completionLogs: []
        )

        // Then: "할 일 1/2/3" 형태
        XCTAssertEqual(summary.displayList[0].displayTitle, "할 일 1")
        XCTAssertEqual(summary.displayList[1].displayTitle, "할 일 2")
        XCTAssertEqual(summary.displayList[2].displayTitle, "할 일 3")
    }

    func testB7_Level2_Hidden_ShowsEmpty() {
        // Given
        let project = Project(id: "p1", title: "My Project", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Secret task", taskType: .oneOff)

        // When
        let summary = computer.compute(
            dateKey: DateKey.today(),
            policy: .todayOverview,
            privacyMode: .hidden,
            projects: [project],
            tasks: [task],
            completionLogs: []
        )

        // Then: 빈 문자열
        XCTAssertEqual(summary.displayList.first?.displayTitle, "")
    }

    // MARK: - PrivacyMasker Unit Tests

    func testMasker_TaskTitle_Visible() {
        let result = masker.maskTaskTitle("Buy groceries", index: 1, privacyMode: .visible)
        XCTAssertEqual(result, "Buy groceries")
    }

    func testMasker_TaskTitle_Visible_Truncated() {
        let longTitle = "This is a very long task title that should be truncated"
        let result = masker.maskTaskTitle(longTitle, index: 1, privacyMode: .visible, maxLength: 20)
        XCTAssertEqual(result.count, 20)
        XCTAssertTrue(result.hasSuffix("…"))
    }

    func testMasker_TaskTitle_Masked() {
        let result = masker.maskTaskTitle("Buy groceries", index: 1, privacyMode: .masked)
        XCTAssertEqual(result, "할 일 1")
    }

    func testMasker_TaskTitle_Hidden() {
        let result = masker.maskTaskTitle("Buy groceries", index: 1, privacyMode: .hidden)
        XCTAssertEqual(result, "")
    }

    func testMasker_ProjectTitle_Visible() {
        let result = masker.maskProjectTitle("My Project", privacyMode: .visible)
        XCTAssertEqual(result, "My Project")
    }

    func testMasker_ProjectTitle_Masked() {
        let result = masker.maskProjectTitle("My Project", privacyMode: .masked)
        XCTAssertEqual(result, "프로젝트")
    }

    func testMasker_ProjectTitle_Hidden() {
        let result = masker.maskProjectTitle("My Project", privacyMode: .hidden)
        XCTAssertEqual(result, "프로젝트")
    }

    // MARK: - Intent Messages

    func testMasker_IntentMessage_Complete_Visible() {
        let result = masker.intentSuccessMessage(
            action: .complete,
            taskTitle: "Buy groceries",
            privacyMode: .visible
        )
        XCTAssertEqual(result, "완료: Buy groceries")
    }

    func testMasker_IntentMessage_Complete_Masked() {
        let result = masker.intentSuccessMessage(
            action: .complete,
            taskTitle: "Buy groceries",
            privacyMode: .masked
        )
        // Level 1에서는 원문 금지
        XCTAssertEqual(result, "완료했습니다")
        XCTAssertFalse(result.contains("Buy"))
    }

    func testMasker_IntentMessage_Complete_Hidden() {
        let result = masker.intentSuccessMessage(
            action: .complete,
            taskTitle: "Secret task",
            privacyMode: .hidden
        )
        // Level 2에서도 원문 금지
        XCTAssertEqual(result, "완료했습니다")
        XCTAssertFalse(result.contains("Secret"))
    }

    func testMasker_IntentMessage_Add() {
        let result = masker.intentSuccessMessage(
            action: .add,
            taskTitle: "New task",
            privacyMode: .visible
        )
        XCTAssertEqual(result, "추가: New task")
    }

    func testMasker_IntentMessage_Refresh() {
        let result = masker.intentSuccessMessage(
            action: .refresh,
            taskTitle: nil,
            privacyMode: .visible
        )
        XCTAssertEqual(result, "갱신했습니다")
    }

    // MARK: - Failure Messages

    func testMasker_FailureMessage_NoTask() {
        let result = masker.intentFailureMessage(reason: .noTaskToComplete)
        XCTAssertEqual(result, "완료할 항목이 없습니다")
    }

    func testMasker_FailureMessage_ProjectNotFound() {
        let result = masker.intentFailureMessage(reason: .projectNotFound)
        XCTAssertEqual(result, "프로젝트를 찾을 수 없습니다")
    }

    func testMasker_FailureMessage_EmptyInput() {
        let result = masker.intentFailureMessage(reason: .emptyInput)
        XCTAssertEqual(result, "내용을 입력해주세요")
    }

    func testMasker_FailureMessage_LoadFailed() {
        let result = masker.intentFailureMessage(reason: .loadFailed)
        XCTAssertEqual(result, "데이터를 불러오지 못했습니다")
    }
}
