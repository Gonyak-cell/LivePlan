import Foundation

/// DateKey 유틸리티
/// - data-model.md B5 준수
/// - 사용자 기기 타임존 기준 YYYY-MM-DD
public struct DateKey: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    public let value: String

    private init(_ value: String) {
        self.value = value
    }

    public var description: String { value }
}

// MARK: - Factory Methods

extension DateKey {
    /// 날짜에서 DateKey 생성 (기기 타임존 기준)
    public static func from(_ date: Date, timeZone: TimeZone = .current) -> DateKey {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timeZone
        return DateKey(formatter.string(from: date))
    }

    /// 오늘의 DateKey (기기 타임존 기준)
    public static func today(timeZone: TimeZone = .current) -> DateKey {
        from(Date(), timeZone: timeZone)
    }

    /// 문자열에서 DateKey 생성 (검증 포함)
    public static func parse(_ string: String) -> DateKey? {
        let pattern = #"^\d{4}-\d{2}-\d{2}$"#
        guard string.range(of: pattern, options: .regularExpression) != nil else {
            return nil
        }
        return DateKey(string)
    }
}

// MARK: - Date Conversion

extension DateKey {
    /// DateKey를 Date로 변환 (해당 날짜의 시작 시간, 기기 타임존 기준)
    public func toDate(timeZone: TimeZone = .current) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timeZone
        return formatter.date(from: value)
    }

    /// 다음 날 DateKey
    public func nextDay(timeZone: TimeZone = .current) -> DateKey? {
        guard let date = toDate(timeZone: timeZone),
              let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: date) else {
            return nil
        }
        return DateKey.from(nextDate, timeZone: timeZone)
    }

    /// 이전 날 DateKey
    public func previousDay(timeZone: TimeZone = .current) -> DateKey? {
        guard let date = toDate(timeZone: timeZone),
              let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: date) else {
            return nil
        }
        return DateKey.from(prevDate, timeZone: timeZone)
    }
}

// MARK: - Comparison

extension DateKey: Comparable {
    public static func < (lhs: DateKey, rhs: DateKey) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - ExpressibleByStringLiteral

extension DateKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
}
