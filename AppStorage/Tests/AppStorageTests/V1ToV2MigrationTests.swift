import XCTest
@testable import AppStorage
@testable import AppCore

/// v1 → v2 마이그레이션 테스트
/// - testing.md A2 준수: 마이그레이션 테스트 필수
/// - data-model.md D 준수
final class V1ToV2MigrationTests: XCTestCase {

    private var migration: V1ToV2Migration!

    override func setUp() {
        super.setUp()
        migration = V1ToV2Migration()
    }

    // MARK: - Basic Migration Tests

    func testMigration_UpdatesSchemaVersion() throws {
        // Given: v1 스냅샷
        let v1Snapshot = createV1Snapshot()

        // When
        let v2Snapshot = try migration.migrate(v1Snapshot)

        // Then
        XCTAssertEqual(v2Snapshot.schemaVersion, 2)
        XCTAssertEqual(v2Snapshot.settings.schemaVersion, 2)
    }

    func testMigration_RejectsNonV1Snapshot() {
        // Given: v2 스냅샷
        let v2Snapshot = DataSnapshot(schemaVersion: 2)

        // When/Then
        XCTAssertThrowsError(try migration.migrate(v2Snapshot)) { error in
            if case MigrationError.unknownVersion(let version) = error {
                XCTAssertEqual(version, 2)
            } else {
                XCTFail("Expected MigrationError.unknownVersion")
            }
        }
    }

    // MARK: - Inbox Project Tests

    func testMigration_AddsInboxIfMissing() throws {
        // Given: Inbox가 없는 v1 스냅샷
        let project = Project(id: "p1", title: "My Project", startDate: Date())
        let v1Snapshot = createV1Snapshot(projects: [project])

        // When
        let v2Snapshot = try migration.migrate(v1Snapshot)

        // Then
        XCTAssertEqual(v2Snapshot.projects.count, 2)
        XCTAssertTrue(v2Snapshot.projects.contains { $0.isInbox })
    }

    func testMigration_PreservesExistingInbox() throws {
        // Given: Inbox가 있는 v1 스냅샷
        let inbox = Project.createInbox()
        let project = Project(id: "p1", title: "My Project", startDate: Date())
        let v1Snapshot = createV1Snapshot(projects: [inbox, project])

        // When
        let v2Snapshot = try migration.migrate(v1Snapshot)

        // Then
        XCTAssertEqual(v2Snapshot.projects.count, 2)
        let inboxCount = v2Snapshot.projects.filter { $0.isInbox }.count
        XCTAssertEqual(inboxCount, 1)
    }

    func testMigration_AddsInboxToEmptyProjects() throws {
        // Given: 프로젝트가 없는 v1 스냅샷
        let v1Snapshot = createV1Snapshot(projects: [])

        // When
        let v2Snapshot = try migration.migrate(v1Snapshot)

        // Then
        XCTAssertEqual(v2Snapshot.projects.count, 1)
        XCTAssertTrue(v2Snapshot.projects.first?.isInbox == true)
    }

    // MARK: - Task Migration Tests

    func testMigration_DailyRecurringGetsRecurrenceRule() throws {
        // Given: dailyRecurring 태스크
        let project = Project(id: "p1", title: "P", startDate: Date())
        let task = Task(
            id: "t1",
            projectId: "p1",
            title: "Daily Task",
            taskType: .dailyRecurring
        )
        let v1Snapshot = createV1Snapshot(projects: [project], tasks: [task])

        // When
        let v2Snapshot = try migration.migrate(v1Snapshot)

        // Then
        let migratedTask = v2Snapshot.tasks.first { $0.id == "t1" }
        XCTAssertNotNil(migratedTask?.recurrenceRule)
        XCTAssertEqual(migratedTask?.recurrenceRule?.kind, .daily)
        XCTAssertEqual(migratedTask?.recurrenceBehavior, .habitReset)
    }

    func testMigration_OneOffTaskUnchanged() throws {
        // Given: oneOff 태스크
        let project = Project(id: "p1", title: "P", startDate: Date())
        let task = Task(
            id: "t1",
            projectId: "p1",
            title: "One Off Task",
            taskType: .oneOff
        )
        let v1Snapshot = createV1Snapshot(projects: [project], tasks: [task])

        // When
        let v2Snapshot = try migration.migrate(v1Snapshot)

        // Then
        let migratedTask = v2Snapshot.tasks.first { $0.id == "t1" }
        XCTAssertNil(migratedTask?.recurrenceRule)
        XCTAssertNil(migratedTask?.recurrenceBehavior)
    }

    func testMigration_PreservesTaskDefaults() throws {
        // Given: v1 태스크 (Phase 2 필드 없음)
        let project = Project(id: "p1", title: "P", startDate: Date())
        let task = Task(
            id: "t1",
            projectId: "p1",
            title: "Task",
            taskType: .oneOff
        )
        let v1Snapshot = createV1Snapshot(projects: [project], tasks: [task])

        // When
        let v2Snapshot = try migration.migrate(v1Snapshot)

        // Then
        let migratedTask = v2Snapshot.tasks.first { $0.id == "t1" }
        XCTAssertEqual(migratedTask?.priority, .p4)
        XCTAssertEqual(migratedTask?.workflowState, .todo)
        XCTAssertTrue(migratedTask?.tagIds.isEmpty == true)
        XCTAssertTrue(migratedTask?.blockedByTaskIds.isEmpty == true)
    }

    // MARK: - Data Preservation Tests

    func testMigration_PreservesCompletionLogs() throws {
        // Given: 완료 로그가 있는 v1 스냅샷
        let project = Project(id: "p1", title: "P", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "T", taskType: .dailyRecurring)
        let log1 = CompletionLog.forDailyRecurring(taskId: "t1", dateKey: "2025-02-01")
        let log2 = CompletionLog.forDailyRecurring(taskId: "t1", dateKey: "2025-02-02")
        let v1Snapshot = createV1Snapshot(
            projects: [project],
            tasks: [task],
            completionLogs: [log1, log2]
        )

        // When
        let v2Snapshot = try migration.migrate(v1Snapshot)

        // Then
        XCTAssertEqual(v2Snapshot.completionLogs.count, 2)
        XCTAssertEqual(v2Snapshot.completionLogs[0].occurrenceKey, "2025-02-01")
        XCTAssertEqual(v2Snapshot.completionLogs[1].occurrenceKey, "2025-02-02")
    }

    func testMigration_PreservesSettings() throws {
        // Given: 설정이 있는 v1 스냅샷
        var settings = AppSettings(schemaVersion: 1)
        settings.privacyMode = .hidden
        settings.pinnedProjectId = "pinned123"
        let v1Snapshot = createV1Snapshot(settings: settings)

        // When
        let v2Snapshot = try migration.migrate(v1Snapshot)

        // Then
        XCTAssertEqual(v2Snapshot.settings.privacyMode, .hidden)
        XCTAssertEqual(v2Snapshot.settings.pinnedProjectId, "pinned123")
        XCTAssertEqual(v2Snapshot.settings.schemaVersion, 2)
    }

    // MARK: - MigrationEngine Integration Tests

    func testMigrationEngine_MigratesV1ToV2() async throws {
        // Given
        let engine = MigrationEngine()
        let v1Snapshot = createV1Snapshot()

        // When
        let result = try await engine.migrate(v1Snapshot)

        // Then
        XCTAssertEqual(result.schemaVersion, 2)
    }

    func testMigrationEngine_V2SnapshotUnchanged() async throws {
        // Given
        let engine = MigrationEngine()
        let v2Snapshot = DataSnapshot(schemaVersion: 2)

        // When
        let result = try await engine.migrate(v2Snapshot)

        // Then
        XCTAssertEqual(result.schemaVersion, 2)
    }

    // MARK: - Helpers

    private func createV1Snapshot(
        projects: [Project] = [],
        tasks: [Task] = [],
        completionLogs: [CompletionLog] = [],
        settings: AppSettings = AppSettings(schemaVersion: 1)
    ) -> DataSnapshot {
        DataSnapshot(
            schemaVersion: 1,
            projects: projects,
            tasks: tasks,
            completionLogs: completionLogs,
            settings: settings,
            sections: [],
            tags: []
        )
    }
}
