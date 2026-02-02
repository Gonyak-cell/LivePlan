import Foundation

/// 날짜/시간 토큰 파서
/// - product-decisions.md 5: 내일/모레/오늘, 요일(월~일), "오후 3시", "3pm"
/// - testing.md B4/B5: 타임존 안전성 준수
public struct DateTokenParser: Sendable {

    public struct ParseResult: Equatable, Sendable {
        public let date: Date?
        public let time: (hour: Int, minute: Int)?
        public let remainingText: String

        public init(date: Date?, time: (hour: Int, minute: Int)?, remainingText: String) {
            self.date = date
            self.time = time
            self.remainingText = remainingText
        }

        // Equatable for time tuple
        public static func == (lhs: ParseResult, rhs: ParseResult) -> Bool {
            lhs.date == rhs.date &&
            lhs.time?.hour == rhs.time?.hour &&
            lhs.time?.minute == rhs.time?.minute &&
            lhs.remainingText == rhs.remainingText
        }
    }

    private let referenceDate: Date
    private let timeZone: TimeZone
    private let calendar: Calendar

    public init(referenceDate: Date = Date(), timeZone: TimeZone = .current) {
        self.referenceDate = referenceDate
        self.timeZone = timeZone
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        self.calendar = calendar
    }

    public func parse(_ text: String) -> ParseResult {
        var remaining = text
        var date: Date?
        var time: (hour: Int, minute: Int)?

        // 1. 상대 날짜 (오늘, 내일, 모레)
        if let (parsed, newRemaining) = parseRelativeDate(from: remaining) {
            date = parsed
            remaining = newRemaining
        }

        // 2. 요일 (월요일, 화, 수 등)
        if date == nil, let (parsed, newRemaining) = parseWeekday(from: remaining) {
            date = parsed
            remaining = newRemaining
        }

        // 3. MM/DD 형식 날짜
        if date == nil, let (parsed, newRemaining) = parseDateFormat(from: remaining) {
            date = parsed
            remaining = newRemaining
        }

        // 4. 시간 (오후 3시, 3pm, 15:30 등)
        if let (parsed, newRemaining) = parseTime(from: remaining) {
            time = parsed
            remaining = newRemaining
        }

        return ParseResult(date: date, time: time, remainingText: remaining)
    }

    // MARK: - Relative Date Parsing

    private func parseRelativeDate(from text: String) -> (Date, String)? {
        let patterns: [(pattern: String, dayOffset: Int)] = [
            ("오늘", 0),
            ("today", 0),
            ("내일", 1),
            ("tomorrow", 1),
            ("모레", 2),
            ("내일모레", 2),
        ]

        for (keyword, offset) in patterns {
            let pattern = "(?i)\\b\(keyword)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let fullRange = Range(match.range, in: text),
               let targetDate = calendar.date(byAdding: .day, value: offset, to: referenceDate) {
                var remaining = text
                remaining.removeSubrange(fullRange)
                return (calendar.startOfDay(for: targetDate), remaining)
            }
        }
        return nil
    }

    // MARK: - Weekday Parsing

    private func parseWeekday(from text: String) -> (Date, String)? {
        // 한글 요일 (긴 형태 먼저 매칭)
        let koreanWeekdays: [(pattern: String, weekday: Int)] = [
            ("월요일", 2), ("화요일", 3), ("수요일", 4),
            ("목요일", 5), ("금요일", 6), ("토요일", 7), ("일요일", 1),
            ("월", 2), ("화", 3), ("수", 4),
            ("목", 5), ("금", 6), ("토", 7), ("일", 1)
        ]

        // 영문 요일
        let englishWeekdays: [(pattern: String, weekday: Int)] = [
            ("monday", 2), ("tuesday", 3), ("wednesday", 4),
            ("thursday", 5), ("friday", 6), ("saturday", 7), ("sunday", 1),
            ("mon", 2), ("tue", 3), ("wed", 4),
            ("thu", 5), ("fri", 6), ("sat", 7), ("sun", 1)
        ]

        let allWeekdays = koreanWeekdays + englishWeekdays

        for (pattern, weekday) in allWeekdays {
            let regexPattern = "(?i)\\b\(pattern)\\b"
            if let regex = try? NSRegularExpression(pattern: regexPattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let fullRange = Range(match.range, in: text),
               let nextDate = nextWeekday(weekday, from: referenceDate) {
                var remaining = text
                remaining.removeSubrange(fullRange)
                return (nextDate, remaining)
            }
        }
        return nil
    }

    private func nextWeekday(_ weekday: Int, from date: Date) -> Date? {
        let currentWeekday = calendar.component(.weekday, from: date)
        var daysToAdd = weekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7  // 다음 주
        }
        guard let result = calendar.date(byAdding: .day, value: daysToAdd, to: date) else {
            return nil
        }
        return calendar.startOfDay(for: result)
    }

    // MARK: - Date Format Parsing

    private func parseDateFormat(from text: String) -> (Date, String)? {
        // MM/DD 형식
        let pattern = #"(\d{1,2})/(\d{1,2})"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let monthRange = Range(match.range(at: 1), in: text),
           let dayRange = Range(match.range(at: 2), in: text),
           let month = Int(text[monthRange]),
           let day = Int(text[dayRange]),
           month >= 1 && month <= 12 && day >= 1 && day <= 31 {

            var components = calendar.dateComponents([.year], from: referenceDate)
            components.month = month
            components.day = day

            if let date = calendar.date(from: components),
               let fullRange = Range(match.range, in: text) {
                var remaining = text
                remaining.removeSubrange(fullRange)
                return (calendar.startOfDay(for: date), remaining)
            }
        }
        return nil
    }

    // MARK: - Time Parsing

    private func parseTime(from text: String) -> ((hour: Int, minute: Int), String)? {
        // 오전/오후 X시 Y분
        if let result = parseKoreanTime(text) {
            return result
        }

        // Xam/Xpm 형식
        if let result = parseAmPmTime(text) {
            return result
        }

        // HH:MM 24시간 형식
        if let result = parseMilitaryTime(text) {
            return result
        }

        // 간단히 "X시" 형식 (24시간 기준)
        if let result = parseSimpleKoreanTime(text) {
            return result
        }

        return nil
    }

    private func parseKoreanTime(_ text: String) -> ((hour: Int, minute: Int), String)? {
        // 오전/오후 X시 Y분
        let pattern = #"(오전|오후)\s*(\d{1,2})시(?:\s*(\d{1,2})분)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let periodRange = Range(match.range(at: 1), in: text),
              let hourRange = Range(match.range(at: 2), in: text) else {
            return nil
        }

        let period = String(text[periodRange])
        guard var hour = Int(text[hourRange]) else { return nil }

        let minute: Int
        if match.range(at: 3).location != NSNotFound,
           let minuteRange = Range(match.range(at: 3), in: text),
           let parsedMinute = Int(text[minuteRange]) {
            minute = parsedMinute
        } else {
            minute = 0
        }

        // 오전/오후 변환
        if period == "오후" && hour < 12 {
            hour += 12
        } else if period == "오전" && hour == 12 {
            hour = 0
        }

        guard hour >= 0 && hour < 24 && minute >= 0 && minute < 60 else { return nil }

        var remaining = text
        if let fullRange = Range(match.range, in: text) {
            remaining.removeSubrange(fullRange)
        }

        return ((hour, minute), remaining)
    }

    private func parseAmPmTime(_ text: String) -> ((hour: Int, minute: Int), String)? {
        // 3pm, 3:30pm, 10am
        let pattern = #"(\d{1,2})(?::(\d{2}))?\s*(am|pm)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let hourRange = Range(match.range(at: 1), in: text),
              let ampmRange = Range(match.range(at: 3), in: text) else {
            return nil
        }

        guard var hour = Int(text[hourRange]) else { return nil }
        let ampm = String(text[ampmRange]).lowercased()

        let minute: Int
        if match.range(at: 2).location != NSNotFound,
           let minuteRange = Range(match.range(at: 2), in: text),
           let parsedMinute = Int(text[minuteRange]) {
            minute = parsedMinute
        } else {
            minute = 0
        }

        if ampm == "pm" && hour < 12 {
            hour += 12
        } else if ampm == "am" && hour == 12 {
            hour = 0
        }

        guard hour >= 0 && hour < 24 && minute >= 0 && minute < 60 else { return nil }

        var remaining = text
        if let fullRange = Range(match.range, in: text) {
            remaining.removeSubrange(fullRange)
        }

        return ((hour, minute), remaining)
    }

    private func parseMilitaryTime(_ text: String) -> ((hour: Int, minute: Int), String)? {
        // 15:30, 9:00
        let pattern = #"(\d{1,2}):(\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let hourRange = Range(match.range(at: 1), in: text),
              let minuteRange = Range(match.range(at: 2), in: text),
              let hour = Int(text[hourRange]),
              let minute = Int(text[minuteRange]),
              hour >= 0 && hour < 24 && minute >= 0 && minute < 60 else {
            return nil
        }

        var remaining = text
        if let fullRange = Range(match.range, in: text) {
            remaining.removeSubrange(fullRange)
        }

        return ((hour, minute), remaining)
    }

    private func parseSimpleKoreanTime(_ text: String) -> ((hour: Int, minute: Int), String)? {
        // X시 Y분 (오전/오후 없이)
        let pattern = #"(\d{1,2})시(?:\s*(\d{1,2})분)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let hourRange = Range(match.range(at: 1), in: text),
              let hour = Int(text[hourRange]),
              hour >= 0 && hour < 24 else {
            return nil
        }

        let minute: Int
        if match.range(at: 2).location != NSNotFound,
           let minuteRange = Range(match.range(at: 2), in: text),
           let parsedMinute = Int(text[minuteRange]) {
            minute = parsedMinute
        } else {
            minute = 0
        }

        guard minute >= 0 && minute < 60 else { return nil }

        var remaining = text
        if let fullRange = Range(match.range, in: text) {
            remaining.removeSubrange(fullRange)
        }

        return ((hour, minute), remaining)
    }
}
