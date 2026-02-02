import XCTest
@testable import AppCore

/// AppSettings 테스트
/// - data-model.md A8 준수
/// - testing.md A2: 마이그레이션/버전 테스트
final class AppSettingsTests: XCTestCase {

    // MARK: - Default Values

    func testDefault_SchemaVersion() {
        let settings = AppSettings.default
        XCTAssertEqual(settings.schemaVersion, AppSettings.currentSchemaVersion)
    }

    func testDefault_PrivacyMode_IsLevel1() {
        let settings = AppSettings.default
        XCTAssertEqual(settings.privacyMode, .level1)
    }

    func testDefault_PinnedProjectId_IsNil() {
        let settings = AppSettings.default
        XCTAssertNil(settings.pinnedProjectId)
    }

    func testDefault_LockscreenSelectionMode_IsPinnedFirst() {
        let settings = AppSettings.default
        XCTAssertEqual(settings.lockscreenSelectionMode, .pinnedFirst)
    }

    func testDefault_DefaultProjectViewType_IsList() {
        let settings = AppSettings.default
        XCTAssertEqual(settings.defaultProjectViewType, .list)
    }

    func testDefault_QuickAddParsingEnabled_IsTrue() {
        let settings = AppSettings.default
        XCTAssertTrue(settings.quickAddParsingEnabled)
    }

    // MARK: - Current Schema Version

    func testCurrentSchemaVersion_IsTwo() {
        XCTAssertEqual(AppSettings.currentSchemaVersion, 2)
    }

    // MARK: - Codable Round-trip

    func testCodable_RoundTrip() throws {
        let original = AppSettings(
            schemaVersion: 2,
            privacyMode: .level2,
            pinnedProjectId: "project-123",
            lockscreenSelectionMode: .todayOverview,
            defaultProjectViewType: .board,
            quickAddParsingEnabled: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testCodable_DefaultValues_RoundTrip() throws {
        let original = AppSettings.default
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Migration from v1

    func testMigration_FromV1_MissingNewFields() throws {
        // v1 데이터: defaultProjectViewType, quickAddParsingEnabled 없음
        let v1JSON = """
        {
            "schemaVersion": 1,
            "privacyMode": "level1",
            "pinnedProjectId": "old-project",
            "lockscreenSelectionMode": "pinnedFirst"
        }
        """

        let data = v1JSON.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        // v1 필드 유지
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.privacyMode, .level1)
        XCTAssertEqual(decoded.pinnedProjectId, "old-project")
        XCTAssertEqual(decoded.lockscreenSelectionMode, .pinnedFirst)

        // 신규 필드 기본값 적용
        XCTAssertEqual(decoded.defaultProjectViewType, .list)
        XCTAssertTrue(decoded.quickAddParsingEnabled)
    }

    func testMigration_FromV1_NoPinnedProject() throws {
        // v1 데이터: pinnedProjectId 없음 (null이 아닌 키 자체 없음)
        let v1JSON = """
        {
            "schemaVersion": 1,
            "privacyMode": "level0",
            "lockscreenSelectionMode": "auto"
        }
        """

        let data = v1JSON.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.privacyMode, .level0)
        XCTAssertNil(decoded.pinnedProjectId)
        XCTAssertEqual(decoded.lockscreenSelectionMode, .auto)
        XCTAssertEqual(decoded.defaultProjectViewType, .list)
        XCTAssertTrue(decoded.quickAddParsingEnabled)
    }

    // MARK: - Equatable

    func testEquatable_SameValues() {
        let a = AppSettings(
            privacyMode: .level1,
            pinnedProjectId: "test",
            lockscreenSelectionMode: .pinnedFirst,
            defaultProjectViewType: .board,
            quickAddParsingEnabled: true
        )
        let b = AppSettings(
            privacyMode: .level1,
            pinnedProjectId: "test",
            lockscreenSelectionMode: .pinnedFirst,
            defaultProjectViewType: .board,
            quickAddParsingEnabled: true
        )

        XCTAssertEqual(a, b)
    }

    func testEquatable_DifferentViewType() {
        let a = AppSettings(defaultProjectViewType: .list)
        let b = AppSettings(defaultProjectViewType: .calendar)

        XCTAssertNotEqual(a, b)
    }

    func testEquatable_DifferentQuickAddParsing() {
        let a = AppSettings(quickAddParsingEnabled: true)
        let b = AppSettings(quickAddParsingEnabled: false)

        XCTAssertNotEqual(a, b)
    }

    // MARK: - LockscreenSelectionMode

    func testLockscreenSelectionMode_AllCases() {
        XCTAssertEqual(LockscreenSelectionMode.allCases.count, 3)
        XCTAssertTrue(LockscreenSelectionMode.allCases.contains(.pinnedFirst))
        XCTAssertTrue(LockscreenSelectionMode.allCases.contains(.todayOverview))
        XCTAssertTrue(LockscreenSelectionMode.allCases.contains(.auto))
    }

    func testLockscreenSelectionMode_Codable() throws {
        for mode in LockscreenSelectionMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(LockscreenSelectionMode.self, from: data)
            XCTAssertEqual(decoded, mode)
        }
    }
}
