import Foundation

/// 완료 로그 저장소 프로토콜
/// - architecture.md D1 준수: AppCore는 프로토콜만 정의
/// - 불변식: (taskId, occurrenceKey) 유니크 보장
public protocol CompletionLogRepository: Sendable {
    /// 모든 완료 로그 조회
    func loadAll() async throws -> [CompletionLog]

    /// 특정 태스크의 완료 로그 조회
    func loadByTask(taskId: String) async throws -> [CompletionLog]

    /// 특정 태스크의 특정 occurrenceKey 완료 로그 조회
    func load(taskId: String, occurrenceKey: String) async throws -> CompletionLog?

    /// 완료 로그 저장
    /// - 중복 저장 시 기존 로그 덮어쓰기 (멱등성)
    func save(_ log: CompletionLog) async throws

    /// 완료 로그 삭제
    func delete(taskId: String, occurrenceKey: String) async throws

    /// 특정 태스크의 모든 완료 로그 삭제
    func deleteByTask(taskId: String) async throws
}

// MARK: - Convenience

extension CompletionLogRepository {
    /// oneOff 태스크 완료 여부 확인
    public func isOneOffCompleted(taskId: String) async throws -> Bool {
        let log = try await load(taskId: taskId, occurrenceKey: CompletionLog.oneOffOccurrenceKey)
        return log != nil
    }

    /// dailyRecurring 태스크의 특정 날짜 완료 여부 확인
    public func isDailyRecurringCompleted(taskId: String, dateKey: DateKey) async throws -> Bool {
        let log = try await load(taskId: taskId, occurrenceKey: dateKey.value)
        return log != nil
    }
}
