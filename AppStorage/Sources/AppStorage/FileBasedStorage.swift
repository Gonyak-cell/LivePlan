import Foundation
import AppCore

/// 파일 기반 저장소
/// - performance.md D1 준수: fail-safe (크래시 금지)
/// - architecture.md D2 준수: 원자적 쓰기
public actor FileBasedStorage {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var cachedSnapshot: DataSnapshot?

    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? AppGroupContainer.effectiveDataFileURL
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    /// 데이터 로드
    /// - fail-safe: 실패 시 빈 상태 반환
    public func load() async -> DataSnapshot {
        // 캐시 확인
        if let cached = cachedSnapshot {
            return cached
        }

        // 파일 로드 시도
        do {
            let snapshot = try await loadFromFile()
            cachedSnapshot = snapshot
            return snapshot
        } catch {
            // fail-safe: 빈 상태 반환
            #if DEBUG
            print("[FileBasedStorage] Load failed, returning empty: \(error)")
            #endif
            let empty = DataSnapshot.withInbox()
            cachedSnapshot = empty
            return empty
        }
    }

    /// 데이터 저장
    public func save(_ snapshot: DataSnapshot) async throws {
        // 디렉토리 생성 보장
        try AppGroupContainer.ensureDirectoryExists()

        // JSON 인코딩
        let data: Data
        do {
            data = try encoder.encode(snapshot)
        } catch {
            throw StorageError.encodingFailed(fileURL.path, error)
        }

        // 원자적 쓰기
        do {
            try data.write(to: fileURL, options: .atomic)
            cachedSnapshot = snapshot
        } catch {
            throw StorageError.writeFailed(fileURL.path, error)
        }
    }

    /// 캐시 무효화
    public func invalidateCache() {
        cachedSnapshot = nil
    }

    /// 파일에서 직접 로드 (캐시 무시)
    private func loadFromFile() async throws -> DataSnapshot {
        // 파일 존재 확인
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return DataSnapshot.withInbox()
        }

        // 파일 읽기
        let data = try Data(contentsOf: fileURL)

        // 디코딩
        do {
            let snapshot = try decoder.decode(DataSnapshot.self, from: data)

            // 마이그레이션 필요 여부 확인
            if snapshot.schemaVersion < AppSettings.currentSchemaVersion {
                return try await MigrationEngine().migrate(snapshot)
            }

            return snapshot
        } catch {
            throw StorageError.decodingFailed(fileURL.path, error)
        }
    }
}

// MARK: - Convenience Methods

extension FileBasedStorage {
    /// 프로젝트 저장
    public func saveProject(_ project: Project) async throws {
        var snapshot = await load()
        if let index = snapshot.projects.firstIndex(where: { $0.id == project.id }) {
            snapshot.projects[index] = project
        } else {
            snapshot.projects.append(project)
        }
        try await save(snapshot)
    }

    /// 프로젝트 삭제
    public func deleteProject(id: String) async throws {
        var snapshot = await load()
        snapshot.projects.removeAll { $0.id == id }
        // 연관 태스크도 삭제
        snapshot.tasks.removeAll { $0.projectId == id }
        try await save(snapshot)
    }

    /// 태스크 저장
    public func saveTask(_ task: Task) async throws {
        var snapshot = await load()
        if let index = snapshot.tasks.firstIndex(where: { $0.id == task.id }) {
            snapshot.tasks[index] = task
        } else {
            snapshot.tasks.append(task)
        }
        try await save(snapshot)
    }

    /// 태스크 삭제
    public func deleteTask(id: String) async throws {
        var snapshot = await load()
        snapshot.tasks.removeAll { $0.id == id }
        // 연관 완료 로그도 삭제
        snapshot.completionLogs.removeAll { $0.taskId == id }
        try await save(snapshot)
    }

    /// 완료 로그 저장 (멱등성)
    public func saveCompletionLog(_ log: CompletionLog) async throws {
        var snapshot = await load()
        // 중복 제거 후 추가
        snapshot.completionLogs.removeAll {
            $0.taskId == log.taskId && $0.occurrenceKey == log.occurrenceKey
        }
        snapshot.completionLogs.append(log)
        try await save(snapshot)
    }

    /// 설정 저장
    public func saveSettings(_ settings: AppSettings) async throws {
        var snapshot = await load()
        snapshot.settings = settings
        try await save(snapshot)
    }

    // MARK: - Section Methods (Phase 2.0)

    /// 섹션 저장
    public func saveSection(_ section: Section) async throws {
        var snapshot = await load()
        if let index = snapshot.sections.firstIndex(where: { $0.id == section.id }) {
            snapshot.sections[index] = section
        } else {
            snapshot.sections.append(section)
        }
        try await save(snapshot)
    }

    /// 섹션 삭제
    /// - 소속 태스크의 sectionId를 nil로 변경
    public func deleteSection(id: String) async throws {
        var snapshot = await load()
        snapshot.sections.removeAll { $0.id == id }
        // 소속 태스크를 미분류로 변경
        for i in snapshot.tasks.indices {
            if snapshot.tasks[i].sectionId == id {
                var task = snapshot.tasks[i]
                task.sectionId = nil
                snapshot.tasks[i] = task
            }
        }
        try await save(snapshot)
    }

    /// 프로젝트의 모든 섹션 삭제
    public func deleteSectionsByProject(projectId: String) async throws {
        var snapshot = await load()
        let sectionIds = Set(snapshot.sections.filter { $0.projectId == projectId }.map { $0.id })
        snapshot.sections.removeAll { $0.projectId == projectId }
        // 소속 태스크를 미분류로 변경
        for i in snapshot.tasks.indices {
            if let sectionId = snapshot.tasks[i].sectionId, sectionIds.contains(sectionId) {
                var task = snapshot.tasks[i]
                task.sectionId = nil
                snapshot.tasks[i] = task
            }
        }
        try await save(snapshot)
    }

    // MARK: - Tag Methods (Phase 2.0)

    /// 태그 저장
    public func saveTag(_ tag: Tag) async throws {
        var snapshot = await load()
        if let index = snapshot.tags.firstIndex(where: { $0.id == tag.id }) {
            snapshot.tags[index] = tag
        } else {
            snapshot.tags.append(tag)
        }
        try await save(snapshot)
    }

    /// 태그 삭제
    /// - 모든 태스크의 tagIds에서 해당 ID 제거
    public func deleteTag(id: String) async throws {
        var snapshot = await load()
        snapshot.tags.removeAll { $0.id == id }
        // 태스크에서 태그 제거
        for i in snapshot.tasks.indices {
            if snapshot.tasks[i].tagIds.contains(id) {
                var task = snapshot.tasks[i]
                task.tagIds.removeAll { $0 == id }
                snapshot.tasks[i] = task
            }
        }
        try await save(snapshot)
    }

    // MARK: - SavedView Methods (Phase 2.0)

    /// 저장된 뷰 저장
    public func saveSavedView(_ view: SavedView) async throws {
        var snapshot = await load()
        if let index = snapshot.savedViews.firstIndex(where: { $0.id == view.id }) {
            snapshot.savedViews[index] = view
        } else {
            snapshot.savedViews.append(view)
        }
        try await save(snapshot)
    }

    /// 저장된 뷰 삭제
    public func deleteSavedView(id: String) async throws {
        var snapshot = await load()
        // Built-in 뷰는 삭제 불가
        guard !snapshot.savedViews.first(where: { $0.id == id })?.isBuiltIn ?? false else {
            return
        }
        snapshot.savedViews.removeAll { $0.id == id }
        try await save(snapshot)
    }

    /// 프로젝트의 모든 저장된 뷰 삭제
    public func deleteSavedViewsByProject(projectId: String) async throws {
        var snapshot = await load()
        snapshot.savedViews.removeAll { $0.scope.projectId == projectId && !$0.isBuiltIn }
        try await save(snapshot)
    }
}
