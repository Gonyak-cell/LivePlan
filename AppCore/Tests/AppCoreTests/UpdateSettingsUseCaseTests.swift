import XCTest
@testable import AppCore

/// UpdateSettingsUseCase 테스트
/// - testing.md A1: AppCore 단위 테스트 필수
/// - data-model.md A8: AppSettings 필드 업데이트 검증
final class UpdateSettingsUseCaseTests: XCTestCase {

    private var settingsRepository: MockSettingsRepository!
    private var sut: UpdateSettingsUseCase!

    override func setUp() {
        super.setUp()
        settingsRepository = MockSettingsRepository()
        sut = UpdateSettingsUseCase(settingsRepository: settingsRepository)
    }

    override func tearDown() {
        settingsRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Privacy Mode

    func testExecute_UpdatePrivacyMode() async throws {
        // Given: 기본 설정 (Level 1)
        XCTAssertEqual(settingsRepository.currentSettings.privacyMode, .l1)

        // When: Level 0으로 변경
        let updated = try await sut.execute(privacyMode: .l0)

        // Then
        XCTAssertEqual(updated.privacyMode, .l0)

        // 저장소에도 반영 확인
        let saved = try await settingsRepository.load()
        XCTAssertEqual(saved.privacyMode, .l0)
    }

    func testExecute_UpdatePrivacyMode_ToLevel2() async throws {
        // When: Level 2로 변경
        let updated = try await sut.execute(privacyMode: .l2)

        // Then
        XCTAssertEqual(updated.privacyMode, .l2)
    }

    // MARK: - Pinned Project ID

    func testExecute_SetPinnedProject() async throws {
        // Given: pinnedProjectId가 없는 상태
        XCTAssertNil(settingsRepository.currentSettings.pinnedProjectId)

        // When: 프로젝트 ID 설정
        let updated = try await sut.execute(pinnedProjectId: .some("project-123"))

        // Then
        XCTAssertEqual(updated.pinnedProjectId, "project-123")
    }

    func testExecute_RemovePinnedProject() async throws {
        // Given: pinnedProjectId가 있는 상태
        settingsRepository.currentSettings.pinnedProjectId = "existing-project"

        // When: 프로젝트 ID 제거
        let updated = try await sut.execute(pinnedProjectId: .none)

        // Then
        XCTAssertNil(updated.pinnedProjectId)
    }

    func testExecute_PinnedProject_Unchanged() async throws {
        // Given
        settingsRepository.currentSettings.pinnedProjectId = "project-456"

        // When: pinnedProjectId 파라미터를 nil로 (변경 안 함)
        let updated = try await sut.execute(privacyMode: .l0)

        // Then: pinnedProjectId는 그대로
        XCTAssertEqual(updated.pinnedProjectId, "project-456")
    }

    // MARK: - Lockscreen Selection Mode

    func testExecute_UpdateLockscreenSelectionMode() async throws {
        // Given
        XCTAssertEqual(settingsRepository.currentSettings.lockscreenSelectionMode, .pinnedFirst)

        // When
        let updated = try await sut.execute(lockscreenSelectionMode: .todayOverview)

        // Then
        XCTAssertEqual(updated.lockscreenSelectionMode, .todayOverview)
    }

    func testExecute_UpdateLockscreenSelectionMode_ToAuto() async throws {
        // When
        let updated = try await sut.execute(lockscreenSelectionMode: .auto)

        // Then
        XCTAssertEqual(updated.lockscreenSelectionMode, .auto)
    }

    // MARK: - Default Project View Type (Phase 2)

    func testExecute_UpdateDefaultProjectViewType() async throws {
        // Given
        XCTAssertEqual(settingsRepository.currentSettings.defaultProjectViewType, .list)

        // When
        let updated = try await sut.execute(defaultProjectViewType: .board)

        // Then
        XCTAssertEqual(updated.defaultProjectViewType, .board)
    }

    func testExecute_UpdateDefaultProjectViewType_ToCalendar() async throws {
        // When
        let updated = try await sut.execute(defaultProjectViewType: .calendar)

        // Then
        XCTAssertEqual(updated.defaultProjectViewType, .calendar)
    }

    // MARK: - Quick Add Parsing Enabled (Phase 2)

    func testExecute_DisableQuickAddParsing() async throws {
        // Given: 기본적으로 활성화됨
        XCTAssertTrue(settingsRepository.currentSettings.quickAddParsingEnabled)

        // When
        let updated = try await sut.execute(quickAddParsingEnabled: false)

        // Then
        XCTAssertFalse(updated.quickAddParsingEnabled)
    }

    func testExecute_EnableQuickAddParsing() async throws {
        // Given
        settingsRepository.currentSettings.quickAddParsingEnabled = false

        // When
        let updated = try await sut.execute(quickAddParsingEnabled: true)

        // Then
        XCTAssertTrue(updated.quickAddParsingEnabled)
    }

    // MARK: - Multiple Fields Update

    func testExecute_UpdateMultipleFields() async throws {
        // Given
        settingsRepository.currentSettings = AppSettings(
            privacyMode: .l1,
            pinnedProjectId: nil,
            lockscreenSelectionMode: .pinnedFirst,
            defaultProjectViewType: .list,
            quickAddParsingEnabled: true
        )

        // When: 여러 필드 동시 업데이트
        let updated = try await sut.execute(
            privacyMode: .l0,
            pinnedProjectId: .some("new-project"),
            lockscreenSelectionMode: .todayOverview,
            defaultProjectViewType: .board,
            quickAddParsingEnabled: false
        )

        // Then: 모든 필드가 업데이트됨
        XCTAssertEqual(updated.privacyMode, .l0)
        XCTAssertEqual(updated.pinnedProjectId, "new-project")
        XCTAssertEqual(updated.lockscreenSelectionMode, .todayOverview)
        XCTAssertEqual(updated.defaultProjectViewType, .board)
        XCTAssertFalse(updated.quickAddParsingEnabled)
    }

    // MARK: - Partial Update (No Change)

    func testExecute_NoParameters_NoChange() async throws {
        // Given
        let original = settingsRepository.currentSettings

        // When: 아무 파라미터도 없음
        let updated = try await sut.execute()

        // Then: 변경 없음
        XCTAssertEqual(updated.privacyMode, original.privacyMode)
        XCTAssertEqual(updated.pinnedProjectId, original.pinnedProjectId)
        XCTAssertEqual(updated.lockscreenSelectionMode, original.lockscreenSelectionMode)
        XCTAssertEqual(updated.defaultProjectViewType, original.defaultProjectViewType)
        XCTAssertEqual(updated.quickAddParsingEnabled, original.quickAddParsingEnabled)
    }

    func testExecute_PartialUpdate_OtherFieldsUnchanged() async throws {
        // Given
        settingsRepository.currentSettings = AppSettings(
            privacyMode: .l1,
            pinnedProjectId: "project-1",
            lockscreenSelectionMode: .auto,
            defaultProjectViewType: .calendar,
            quickAddParsingEnabled: false
        )

        // When: 하나만 업데이트
        let updated = try await sut.execute(privacyMode: .l2)

        // Then: 나머지는 그대로
        XCTAssertEqual(updated.privacyMode, .l2) // 변경됨
        XCTAssertEqual(updated.pinnedProjectId, "project-1") // 유지
        XCTAssertEqual(updated.lockscreenSelectionMode, .auto) // 유지
        XCTAssertEqual(updated.defaultProjectViewType, .calendar) // 유지
        XCTAssertFalse(updated.quickAddParsingEnabled) // 유지
    }

    // MARK: - Schema Version Preservation

    func testExecute_SchemaVersionPreserved() async throws {
        // Given
        let originalVersion = settingsRepository.currentSettings.schemaVersion

        // When
        let updated = try await sut.execute(privacyMode: .l0)

        // Then: schemaVersion은 변경되지 않음
        XCTAssertEqual(updated.schemaVersion, originalVersion)
    }

    // MARK: - Persistence

    func testExecute_SettingsAreSaved() async throws {
        // When
        _ = try await sut.execute(privacyMode: .l2)

        // Then: 저장소에 반영됨
        let saved = try await settingsRepository.load()
        XCTAssertEqual(saved.privacyMode, .l2)
    }

    // MARK: - Error Description

    func testUpdateSettingsError_ErrorDescriptions() {
        XCTAssertEqual(UpdateSettingsError.loadFailed.errorDescription, "Failed to load settings")
        XCTAssertEqual(UpdateSettingsError.saveFailed.errorDescription, "Failed to save settings")
    }
}

// MARK: - Mock Repository

private final class MockSettingsRepository: SettingsRepository, @unchecked Sendable {
    var currentSettings: AppSettings = .default

    func load() async throws -> AppSettings {
        currentSettings
    }

    func save(_ settings: AppSettings) async throws {
        currentSettings = settings
    }
}
