import XCTest
@testable import AppStorage
@testable import AppCore

/// 저장소 Fail-safe 테스트
/// - testing.md A2, performance.md D1 준수
final class StorageFailSafeTests: XCTestCase {

    private var tempURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("data.json")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent())
        try await super.tearDown()
    }

    // MARK: - Fail-safe Tests

    func testFailSafe_FileNotFound_ReturnsEmptyWithInbox() async {
        // Given: 파일이 존재하지 않음
        let storage = FileBasedStorage(fileURL: tempURL)

        // When: 로드 시도
        let loaded = await storage.load()

        // Then: 빈 상태 + Inbox 반환 (크래시 없음)
        XCTAssertTrue(loaded.projects.contains { $0.isInbox })
        XCTAssertTrue(loaded.tasks.isEmpty)
        XCTAssertTrue(loaded.completionLogs.isEmpty)
    }

    func testFailSafe_CorruptedJSON_ReturnsEmpty() async {
        // Given: 손상된 JSON 파일
        let dir = tempURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let corruptedData = "{ invalid json content".data(using: .utf8)!
        try? corruptedData.write(to: tempURL)

        let storage = FileBasedStorage(fileURL: tempURL)

        // When: 로드 시도
        let loaded = await storage.load()

        // Then: 빈 상태 반환 (크래시 없음)
        XCTAssertTrue(loaded.projects.contains { $0.isInbox })
    }

    func testFailSafe_EmptyFile_ReturnsEmpty() async {
        // Given: 빈 파일
        let dir = tempURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? Data().write(to: tempURL)

        let storage = FileBasedStorage(fileURL: tempURL)

        // When
        let loaded = await storage.load()

        // Then: 빈 상태 반환
        XCTAssertTrue(loaded.projects.contains { $0.isInbox })
    }

    func testFailSafe_PartialData_ReturnsEmpty() async {
        // Given: 부분적인 데이터 (필드 누락)
        let partialJSON = """
        {
            "schemaVersion": 1,
            "projects": []
        }
        """.data(using: .utf8)!

        let dir = tempURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? partialJSON.write(to: tempURL)

        let storage = FileBasedStorage(fileURL: tempURL)

        // When
        let loaded = await storage.load()

        // Then: 빈 상태 반환 (크래시 없음)
        XCTAssertNotNil(loaded)
    }

    // MARK: - Recovery Tests

    func testRecovery_AfterCorruption_CanSaveNew() async throws {
        // Given: 손상된 파일
        let dir = tempURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try "corrupted".data(using: .utf8)!.write(to: tempURL)

        let storage = FileBasedStorage(fileURL: tempURL)

        // When: 새 데이터 저장
        let newSnapshot = DataSnapshot.withInbox()
        try await storage.save(newSnapshot)

        // Then: 복구 가능
        let loaded = await storage.load()
        XCTAssertTrue(loaded.projects.contains { $0.isInbox })
    }

    // MARK: - Atomic Write Tests

    func testAtomicWrite_DataIntegrity() async throws {
        // Given
        let storage = FileBasedStorage(fileURL: tempURL)
        let project = Project(id: "p1", title: "Test", startDate: Date())
        let snapshot = DataSnapshot(projects: [project])

        // When: 저장
        try await storage.save(snapshot)

        // Then: 파일이 완전히 작성됨
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

        let data = try Data(contentsOf: tempURL)
        XCTAssertFalse(data.isEmpty)

        // JSON 파싱 가능
        let decoded = try JSONDecoder().decode(DataSnapshot.self, from: data)
        XCTAssertEqual(decoded.projects.first?.id, "p1")
    }
}
