import Foundation

/// 완료 기록 엔티티
/// - data-model.md A6 준수
/// - 불변식: (taskId, occurrenceKey) 유니크
public struct CompletionLog: Identifiable, Codable, Equatable, Sendable {
    public var id: String { "\(taskId)_\(occurrenceKey)" }
    public let taskId: String
    public let completedAt: Date
    public let occurrenceKey: String

    public init(
        taskId: String,
        completedAt: Date = Date(),
        occurrenceKey: String
    ) {
        self.taskId = taskId
        self.completedAt = completedAt
        self.occurrenceKey = occurrenceKey
    }
}

// MARK: - OccurrenceKey Constants

extension CompletionLog {
    /// oneOff 태스크의 고정 occurrenceKey
    public static let oneOffOccurrenceKey = "once"

    /// oneOff 태스크용 CompletionLog 생성
    public static func forOneOff(taskId: String, completedAt: Date = Date()) -> CompletionLog {
        CompletionLog(
            taskId: taskId,
            completedAt: completedAt,
            occurrenceKey: oneOffOccurrenceKey
        )
    }

    /// dailyRecurring 태스크용 CompletionLog 생성
    /// - Parameter dateKey: YYYY-MM-DD 형식의 날짜 키
    public static func forDailyRecurring(
        taskId: String,
        dateKey: String,
        completedAt: Date = Date()
    ) -> CompletionLog {
        CompletionLog(
            taskId: taskId,
            completedAt: completedAt,
            occurrenceKey: dateKey
        )
    }

    /// rollover 반복 태스크용 CompletionLog 생성
    /// - Parameters:
    ///   - taskId: 태스크 ID
    ///   - occurrenceDueAt: 현재 occurrence의 마감일 (nextOccurrenceDueAt)
    ///   - completedAt: 완료 시간
    ///   - timeZone: 타임존 (기본: 현재)
    /// - Returns: CompletionLog (occurrenceKey = occurrenceDueAt의 dateKey)
    /// - data-model.md B3: rollover occurrenceKey = dateKey(nextOccurrenceDueAt)
    public static func forRollover(
        taskId: String,
        occurrenceDueAt: Date,
        completedAt: Date = Date(),
        timeZone: TimeZone = .current
    ) -> CompletionLog {
        let occurrenceKey = DateKey.from(occurrenceDueAt, timeZone: timeZone).value
        return CompletionLog(
            taskId: taskId,
            completedAt: completedAt,
            occurrenceKey: occurrenceKey
        )
    }
}

// MARK: - Validation

extension CompletionLog {
    /// oneOff 완료 여부
    public var isOneOffCompletion: Bool {
        occurrenceKey == Self.oneOffOccurrenceKey
    }

    /// dailyRecurring 완료 여부
    public var isDailyRecurringCompletion: Bool {
        !isOneOffCompletion
    }
}
