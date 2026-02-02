import XCTest
@testable import AppStorage
@testable import AppCore

/// 저장소 라운드트립 테스트
/// - testing.md A2 준수
final class StorageRoundTripTests: XCTestCase {

    private var storage: FileBasedStorage!
    private var tempURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("data.json")
        storage = FileBasedStorage(fileURL: tempURL)
    }

    override func tearDown() async throws {
        // 임시 파일 정리
        try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent())
        try await super.tearDown()
    }

    // MARK: - Round Trip Tests

    func testRoundTrip_EmptySnapshot() async throws {
        // Given
        let original = DataSnapshot.empty

        // When
        try await storage.save(original)
        let loaded = await storage.load()

        // Then
        XCTAssertEqual(loaded.schemaVersion, original.schemaVersion)
        XCTAssertTrue(loaded.projects.isEmpty)
        XCTAssertTrue(loaded.tasks.isEmpty)
        XCTAssertTrue(loaded.completionLogs.isEmpty)
    }

    func testRoundTrip_SingleProject() async throws {
        // Given
        let project = Project(id: "p1", title: "Test Project", startDate: Date())
        let original = DataSnapshot(projects: [project])

        // When
        try await storage.save(original)
        let loaded = await storage.load()

        // Then
        XCTAssertEqual(loaded.projects.count, 1)
        XCTAssertEqual(loaded.projects.first?.id, project.id)
        XCTAssertEqual(loaded.projects.first?.title, project.title)
    }

    func testRoundTrip_ProjectWithTasks() async throws {
        // Given
        let project = Project(id: "p1", title: "Test Project", startDate: Date())
        let task1 = Task(id: "t1", projectId: "p1", title: "Task 1", taskType: .oneOff)
        let task2 = Task(id: "t2", projectId: "p1", title: "Task 2", taskType: .dailyRecurring)
        let original = DataSnapshot(projects: [project], tasks: [task1, task2])

        // When
        try await storage.save(original)
        let loaded = await storage.load()

        // Then
        XCTAssertEqual(loaded.projects.count, 1)
        XCTAssertEqual(loaded.tasks.count, 2)
        XCTAssertEqual(loaded.tasks.first { $0.id == "t1" }?.taskType, .oneOff)
        XCTAssertEqual(loaded.tasks.first { $0.id == "t2" }?.taskType, .dailyRecurring)
    }

    func testRoundTrip_CompletionLogs() async throws {
        // Given
        let project = Project(id: "p1", title: "Test", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "Task", taskType: .dailyRecurring)
        let log1 = CompletionLog.forDailyRecurring(taskId: "t1", dateKey: "2025-02-01")
        let log2 = CompletionLog.forDailyRecurring(taskId: "t1", dateKey: "2025-02-02")
        let original = DataSnapshot(
            projects: [project],
            tasks: [task],
            completionLogs: [log1, log2]
        )

        // When
        try await storage.save(original)
        let loaded = await storage.load()

        // Then
        XCTAssertEqual(loaded.completionLogs.count, 2)
    }

    func testRoundTrip_Settings() async throws {
        // Given
        var settings = AppSettings.default
        settings.privacyMode = .hidden
        settings.pinnedProjectId = "pinned123"
        let original = DataSnapshot(settings: settings)

        // When
        try await storage.save(original)
        let loaded = await storage.load()

        // Then
        XCTAssertEqual(loaded.settings.privacyMode, .hidden)
        XCTAssertEqual(loaded.settings.pinnedProjectId, "pinned123")
    }

    // MARK: - Unique Constraint Tests

    func testValidation_DuplicateProjectId() {
        // Given
        let project1 = Project(id: "dup", title: "P1", startDate: Date())
        let project2 = Project(id: "dup", title: "P2", startDate: Date())
        let snapshot = DataSnapshot(projects: [project1, project2])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains(.duplicateProjectId))
    }

    func testValidation_DuplicateTaskId() {
        // Given
        let project = Project(id: "p1", title: "P", startDate: Date())
        let task1 = Task(id: "dup", projectId: "p1", title: "T1", taskType: .oneOff)
        let task2 = Task(id: "dup", projectId: "p1", title: "T2", taskType: .oneOff)
        let snapshot = DataSnapshot(projects: [project], tasks: [task1, task2])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains(.duplicateTaskId))
    }

    func testValidation_DuplicateCompletionLog() {
        // Given
        let log1 = CompletionLog.forDailyRecurring(taskId: "t1", dateKey: "2025-02-01")
        let log2 = CompletionLog.forDailyRecurring(taskId: "t1", dateKey: "2025-02-01")
        let snapshot = DataSnapshot(completionLogs: [log1, log2])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains(.duplicateCompletionLog))
    }

    func testValidation_OrphanedTask() {
        // Given: 존재하지 않는 프로젝트를 참조하는 태스크
        let task = Task(id: "t1", projectId: "nonexistent", title: "T", taskType: .oneOff)
        let snapshot = DataSnapshot(projects: [], tasks: [task])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains { error in
            if case .orphanedTask(_, "nonexistent") = error {
                return true
            }
            return false
        })
    }

    // MARK: - Phase 2.0: Section/Tag Tests

    func testRoundTrip_SectionsAndTags() async throws {
        // Given
        let project = Project(id: "p1", title: "Test Project", startDate: Date())
        let section = Section(id: "s1", projectId: "p1", title: "Section 1")
        let tag = Tag(id: "tag1", name: "Work")
        let task = Task(
            id: "t1",
            projectId: "p1",
            title: "Task 1",
            taskType: .oneOff,
            sectionId: "s1",
            tagIds: ["tag1"]
        )
        let original = DataSnapshot(
            projects: [project],
            tasks: [task],
            sections: [section],
            tags: [tag]
        )

        // When
        try await storage.save(original)
        let loaded = await storage.load()

        // Then
        XCTAssertEqual(loaded.sections.count, 1)
        XCTAssertEqual(loaded.sections.first?.id, "s1")
        XCTAssertEqual(loaded.sections.first?.title, "Section 1")
        XCTAssertEqual(loaded.tags.count, 1)
        XCTAssertEqual(loaded.tags.first?.id, "tag1")
        XCTAssertEqual(loaded.tags.first?.name, "Work")
    }

    func testValidation_DuplicateSectionId() {
        // Given
        let project = Project(id: "p1", title: "P", startDate: Date())
        let section1 = Section(id: "dup", projectId: "p1", title: "S1")
        let section2 = Section(id: "dup", projectId: "p1", title: "S2")
        let snapshot = DataSnapshot(projects: [project], sections: [section1, section2])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains(.duplicateSectionId))
    }

    func testValidation_DuplicateTagId() {
        // Given
        let tag1 = Tag(id: "dup", name: "Tag1")
        let tag2 = Tag(id: "dup", name: "Tag2")
        let snapshot = DataSnapshot(tags: [tag1, tag2])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains(.duplicateTagId))
    }

    func testValidation_OrphanedSection() {
        // Given: 존재하지 않는 프로젝트를 참조하는 섹션
        let section = Section(id: "s1", projectId: "nonexistent", title: "S")
        let snapshot = DataSnapshot(sections: [section])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains { error in
            if case .orphanedSection(_, "nonexistent") = error {
                return true
            }
            return false
        })
    }

    func testValidation_InvalidSectionReference() {
        // Given: 존재하지 않는 섹션을 참조하는 태스크
        let project = Project(id: "p1", title: "P", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "T", taskType: .oneOff, sectionId: "nonexistent")
        let snapshot = DataSnapshot(projects: [project], tasks: [task])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains { error in
            if case .invalidSectionReference(_, "nonexistent") = error {
                return true
            }
            return false
        })
    }

    func testValidation_InvalidTagReference() {
        // Given: 존재하지 않는 태그를 참조하는 태스크
        let project = Project(id: "p1", title: "P", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "T", taskType: .oneOff, tagIds: ["nonexistent"])
        let snapshot = DataSnapshot(projects: [project], tasks: [task])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains { error in
            if case .invalidTagReference(_, "nonexistent") = error {
                return true
            }
            return false
        })
    }

    func testValidation_SelfBlockingTask() {
        // Given: 자기 자신을 차단하는 태스크
        let project = Project(id: "p1", title: "P", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "T", taskType: .oneOff, blockedByTaskIds: ["t1"])
        let snapshot = DataSnapshot(projects: [project], tasks: [task])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains(.selfBlockingTask("t1")))
    }

    func testValidation_InvalidBlockedByReference() {
        // Given: 존재하지 않는 태스크를 참조하는 blockedByTaskIds
        let project = Project(id: "p1", title: "P", startDate: Date())
        let task = Task(id: "t1", projectId: "p1", title: "T", taskType: .oneOff, blockedByTaskIds: ["nonexistent"])
        let snapshot = DataSnapshot(projects: [project], tasks: [task])

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.contains { error in
            if case .invalidBlockedByReference(_, "nonexistent") = error {
                return true
            }
            return false
        })
    }

    func testValidation_ValidSnapshot_NoErrors() {
        // Given: 모든 참조가 올바른 스냅샷
        let project = Project(id: "p1", title: "P", startDate: Date())
        let section = Section(id: "s1", projectId: "p1", title: "S")
        let tag = Tag(id: "tag1", name: "Work")
        let task1 = Task(id: "t1", projectId: "p1", title: "T1", taskType: .oneOff, sectionId: "s1", tagIds: ["tag1"])
        let task2 = Task(id: "t2", projectId: "p1", title: "T2", taskType: .oneOff, blockedByTaskIds: ["t1"])
        let snapshot = DataSnapshot(
            projects: [project],
            tasks: [task1, task2],
            sections: [section],
            tags: [tag]
        )

        // When
        let errors = snapshot.validate()

        // Then
        XCTAssertTrue(errors.isEmpty)
    }

    // MARK: - Phase 2.0: SavedView Tests

    func testRoundTrip_SavedViews() async throws {
        // Given
        let view1 = SavedView.builtIn(
            id: "today",
            name: "Today",
            definition: FilterDefinition(dueRange: .today),
            sortOrder: 0
        )
        let view2 = SavedView.custom(
            name: "My Filter",
            definition: FilterDefinition(priorityAtLeast: .p1)
        )
        let original = DataSnapshot(savedViews: [view1, view2])

        // When
        try await storage.save(original)
        let loaded = await storage.load()

        // Then
        XCTAssertEqual(loaded.savedViews.count, 2)
        XCTAssertTrue(loaded.savedViews.contains { $0.id == "today" && $0.isBuiltIn })
        XCTAssertTrue(loaded.savedViews.contains { $0.name == "My Filter" && !$0.isBuiltIn })
    }

    func testRoundTrip_SavedViewWithProjectScope() async throws {
        // Given
        let project = Project(id: "p1", title: "Test", startDate: Date())
        let view = SavedView(
            name: "Project Filter",
            scope: .project("p1"),
            viewType: .board,
            definition: FilterDefinition(stateIn: [.todo, .doing])
        )
        let original = DataSnapshot(projects: [project], savedViews: [view])

        // When
        try await storage.save(original)
        let loaded = await storage.load()

        // Then
        XCTAssertEqual(loaded.savedViews.count, 1)
        XCTAssertEqual(loaded.savedViews.first?.scope.projectId, "p1")
        XCTAssertEqual(loaded.savedViews.first?.viewType, .board)
    }

    // MARK: - Repository Tests

    func testFileSectionRepository_SaveAndLoad() async throws {
        // Given
        let sectionRepo = FileSectionRepository(storage: storage)
        let project = Project(id: "p1", title: "Test", startDate: Date())
        try await storage.saveProject(project)

        let section = Section(id: "s1", projectId: "p1", title: "Section 1")

        // When
        try await sectionRepo.save(section)
        let loaded = try await sectionRepo.load(id: "s1")

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.title, "Section 1")
    }

    func testFileSectionRepository_DeleteRemovesSectionAndClearsTaskReference() async throws {
        // Given
        let sectionRepo = FileSectionRepository(storage: storage)
        let project = Project(id: "p1", title: "Test", startDate: Date())
        let section = Section(id: "s1", projectId: "p1", title: "Section 1")
        let task = Task(id: "t1", projectId: "p1", title: "Task", taskType: .oneOff, sectionId: "s1")

        try await storage.saveProject(project)
        try await sectionRepo.save(section)
        try await storage.saveTask(task)

        // When
        try await sectionRepo.delete(id: "s1")

        // Then
        let loadedSection = try await sectionRepo.load(id: "s1")
        XCTAssertNil(loadedSection)

        let snapshot = await storage.load()
        let loadedTask = snapshot.tasks.first { $0.id == "t1" }
        XCTAssertNil(loadedTask?.sectionId, "Task's sectionId should be nil after section deletion")
    }

    func testFileTagRepository_SaveAndLoad() async throws {
        // Given
        let tagRepo = FileTagRepository(storage: storage)
        let tag = Tag(id: "tag1", name: "Work")

        // When
        try await tagRepo.save(tag)
        let loaded = try await tagRepo.load(id: "tag1")

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.name, "Work")
    }

    func testFileTagRepository_LoadByName_CaseInsensitive() async throws {
        // Given
        let tagRepo = FileTagRepository(storage: storage)
        let tag = Tag(id: "tag1", name: "Work")
        try await tagRepo.save(tag)

        // When
        let loaded = try await tagRepo.load(byName: "WORK")

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, "tag1")
    }

    func testFileTagRepository_DeleteRemovesTagAndClearsTaskReference() async throws {
        // Given
        let tagRepo = FileTagRepository(storage: storage)
        let project = Project(id: "p1", title: "Test", startDate: Date())
        let tag = Tag(id: "tag1", name: "Work")
        let task = Task(id: "t1", projectId: "p1", title: "Task", taskType: .oneOff, tagIds: ["tag1", "tag2"])

        try await storage.saveProject(project)
        try await tagRepo.save(tag)
        try await storage.saveTask(task)

        // When
        try await tagRepo.delete(id: "tag1")

        // Then
        let loadedTag = try await tagRepo.load(id: "tag1")
        XCTAssertNil(loadedTag)

        let snapshot = await storage.load()
        let loadedTask = snapshot.tasks.first { $0.id == "t1" }
        XCTAssertEqual(loadedTask?.tagIds, ["tag2"], "Task's tagIds should not contain deleted tag")
    }

    func testFileSavedViewRepository_SaveAndLoad() async throws {
        // Given
        let viewRepo = FileSavedViewRepository(storage: storage)
        let view = SavedView.custom(
            name: "My Filter",
            definition: FilterDefinition(priorityAtLeast: .p1)
        )

        // When
        try await viewRepo.save(view)
        let loaded = try await viewRepo.load(id: view.id)

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.name, "My Filter")
    }

    func testFileSavedViewRepository_BuiltInCannotBeDeleted() async throws {
        // Given
        let viewRepo = FileSavedViewRepository(storage: storage)
        let builtInView = SavedView.builtIn(
            id: "today",
            name: "Today",
            definition: FilterDefinition(dueRange: .today),
            sortOrder: 0
        )
        try await viewRepo.save(builtInView)

        // When
        try await viewRepo.delete(id: "today")

        // Then
        let loaded = try await viewRepo.load(id: "today")
        XCTAssertNotNil(loaded, "Built-in view should not be deleted")
    }

    func testFileSavedViewRepository_CustomCanBeDeleted() async throws {
        // Given
        let viewRepo = FileSavedViewRepository(storage: storage)
        let customView = SavedView.custom(
            name: "Custom Filter",
            definition: FilterDefinition()
        )
        try await viewRepo.save(customView)

        // When
        try await viewRepo.delete(id: customView.id)

        // Then
        let loaded = try await viewRepo.load(id: customView.id)
        XCTAssertNil(loaded, "Custom view should be deleted")
    }

    func testFileSavedViewRepository_LoadGlobalAndByProject() async throws {
        // Given
        let viewRepo = FileSavedViewRepository(storage: storage)
        let project = Project(id: "p1", title: "Test", startDate: Date())
        try await storage.saveProject(project)

        let globalView = SavedView.custom(name: "Global", definition: FilterDefinition())
        let projectView = SavedView(
            name: "Project View",
            scope: .project("p1"),
            viewType: .list,
            definition: FilterDefinition()
        )
        try await viewRepo.save(globalView)
        try await viewRepo.save(projectView)

        // When
        let globals = try await viewRepo.loadGlobal()
        let projectViews = try await viewRepo.loadByProject(projectId: "p1")

        // Then
        XCTAssertEqual(globals.count, 1)
        XCTAssertEqual(globals.first?.name, "Global")
        XCTAssertEqual(projectViews.count, 1)
        XCTAssertEqual(projectViews.first?.name, "Project View")
    }
}
