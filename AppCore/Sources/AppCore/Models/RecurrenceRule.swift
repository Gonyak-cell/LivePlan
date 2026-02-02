import Foundation

/// 반복 규칙
/// - data-model.md A5 준수
/// - 매일/주간/월간 반복 지원 (Phase 2)
public struct RecurrenceRule: Codable, Equatable, Sendable {
    /// 반복 종류
    public var kind: RecurrenceKind

    /// 반복 간격 (기본 1)
    /// - 예: interval=2, kind=weekly -> 격주
    public var interval: Int

    /// 요일 (weekly일 때만 사용)
    public var weekdays: Set<Weekday>

    /// 시간 (선택)
    public var timeOfDay: TimeOfDay?

    /// 반복 기준점
    public var anchorDate: Date

    public init(
        kind: RecurrenceKind,
        interval: Int = 1,
        weekdays: Set<Weekday> = [],
        timeOfDay: TimeOfDay? = nil,
        anchorDate: Date = Date()
    ) {
        self.kind = kind
        self.interval = max(1, interval) // interval <= 0 금지
        self.weekdays = weekdays
        self.timeOfDay = timeOfDay
        self.anchorDate = anchorDate
    }
}

// MARK: - RecurrenceKind

/// 반복 종류
public enum RecurrenceKind: String, Codable, CaseIterable, Sendable {
    /// 매일
    case daily

    /// 매주
    case weekly

    /// 매월
    case monthly
}

extension RecurrenceKind {
    /// 사용자 표시용 설명 (KR)
    public var descriptionKR: String {
        switch self {
        case .daily: return "매일"
        case .weekly: return "매주"
        case .monthly: return "매월"
        }
    }

    /// 사용자 표시용 설명 (EN)
    public var descriptionEN: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

// MARK: - Weekday

/// 요일
public enum Weekday: Int, Codable, CaseIterable, Sendable, Comparable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    public static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Weekday {
    /// 짧은 라벨 (KR)
    public var shortLabelKR: String {
        switch self {
        case .sunday: return "일"
        case .monday: return "월"
        case .tuesday: return "화"
        case .wednesday: return "수"
        case .thursday: return "목"
        case .friday: return "금"
        case .saturday: return "토"
        }
    }

    /// 짧은 라벨 (EN)
    public var shortLabelEN: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    /// Calendar.Component.weekday와 호환 (1=Sunday)
    public var calendarWeekday: Int {
        rawValue
    }

    /// Calendar weekday로부터 생성
    public init?(calendarWeekday: Int) {
        self.init(rawValue: calendarWeekday)
    }
}

// MARK: - TimeOfDay

/// 시간 (시:분)
public struct TimeOfDay: Codable, Equatable, Sendable, Comparable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        if lhs.hour != rhs.hour {
            return lhs.hour < rhs.hour
        }
        return lhs.minute < rhs.minute
    }
}

extension TimeOfDay {
    /// 포맷된 문자열 (HH:mm)
    public var formatted: String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// 12시간제 포맷 (EN)
    public var formatted12Hour: String {
        let period = hour < 12 ? "AM" : "PM"
        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", hour12, minute, period)
    }

    /// 오전/오후 포맷 (KR)
    public var formattedKR: String {
        let period = hour < 12 ? "오전" : "오후"
        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%@ %d:%02d", period, hour12, minute)
    }
}

// MARK: - Validation

extension RecurrenceRule {
    /// 유효성 검사 결과
    public enum ValidationError: Error, Equatable {
        /// interval이 0 이하
        case invalidInterval
        /// weekly인데 weekdays가 비어있음
        case weeklyWithoutWeekdays
    }

    /// 유효성 검사
    public func validate() -> ValidationError? {
        if interval <= 0 {
            return .invalidInterval
        }
        if kind == .weekly && weekdays.isEmpty {
            return .weeklyWithoutWeekdays
        }
        return nil
    }

    /// 유효한 규칙인지 여부
    public var isValid: Bool {
        validate() == nil
    }
}

// MARK: - Factory Methods

extension RecurrenceRule {
    /// 매일 반복 생성
    public static func daily(
        interval: Int = 1,
        timeOfDay: TimeOfDay? = nil,
        anchorDate: Date = Date()
    ) -> RecurrenceRule {
        RecurrenceRule(
            kind: .daily,
            interval: interval,
            timeOfDay: timeOfDay,
            anchorDate: anchorDate
        )
    }

    /// 매주 반복 생성
    public static func weekly(
        weekdays: Set<Weekday>,
        interval: Int = 1,
        timeOfDay: TimeOfDay? = nil,
        anchorDate: Date = Date()
    ) -> RecurrenceRule {
        RecurrenceRule(
            kind: .weekly,
            interval: interval,
            weekdays: weekdays,
            timeOfDay: timeOfDay,
            anchorDate: anchorDate
        )
    }

    /// 평일 반복 (월~금)
    public static func weekdays(
        interval: Int = 1,
        timeOfDay: TimeOfDay? = nil,
        anchorDate: Date = Date()
    ) -> RecurrenceRule {
        RecurrenceRule(
            kind: .weekly,
            interval: interval,
            weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            timeOfDay: timeOfDay,
            anchorDate: anchorDate
        )
    }

    /// 매월 반복 생성
    public static func monthly(
        interval: Int = 1,
        timeOfDay: TimeOfDay? = nil,
        anchorDate: Date = Date()
    ) -> RecurrenceRule {
        RecurrenceRule(
            kind: .monthly,
            interval: interval,
            timeOfDay: timeOfDay,
            anchorDate: anchorDate
        )
    }
}

// MARK: - Next Occurrence Calculation

extension RecurrenceRule {
    /// 주어진 날짜 이후의 다음 occurrence 날짜 계산 (rollover용)
    /// - Parameters:
    ///   - date: 기준 날짜
    ///   - calendar: 사용할 캘린더 (기본: 현재)
    /// - Returns: 다음 occurrence 날짜
    public func nextOccurrence(after date: Date, calendar: Calendar = .current) -> Date? {
        switch kind {
        case .daily:
            return nextDailyOccurrence(after: date, calendar: calendar)
        case .weekly:
            return nextWeeklyOccurrence(after: date, calendar: calendar)
        case .monthly:
            return nextMonthlyOccurrence(after: date, calendar: calendar)
        }
    }

    /// 매일 반복의 다음 occurrence
    private func nextDailyOccurrence(after date: Date, calendar: Calendar) -> Date? {
        // interval일 후
        guard let next = calendar.date(byAdding: .day, value: interval, to: date) else {
            return nil
        }
        return applyTimeOfDay(to: next, calendar: calendar)
    }

    /// 매주 반복의 다음 occurrence
    private func nextWeeklyOccurrence(after date: Date, calendar: Calendar) -> Date? {
        guard !weekdays.isEmpty else { return nil }

        // 현재 요일 확인
        let currentWeekday = calendar.component(.weekday, from: date)

        // 같은 주 내에서 다음 요일 찾기
        let sortedWeekdays = weekdays.map { $0.calendarWeekday }.sorted()

        // 현재 요일보다 큰 요일 찾기 (같은 interval 주 내)
        if let nextDayInWeek = sortedWeekdays.first(where: { $0 > currentWeekday }) {
            let daysToAdd = nextDayInWeek - currentWeekday
            if let next = calendar.date(byAdding: .day, value: daysToAdd, to: date) {
                return applyTimeOfDay(to: next, calendar: calendar)
            }
        }

        // 다음 interval 주의 첫 번째 요일로 이동
        guard let firstDayOfWeekdays = sortedWeekdays.first else { return nil }

        // 다음 주 시작까지의 일수 계산
        let daysUntilNextWeek = 7 - currentWeekday + firstDayOfWeekdays + (interval - 1) * 7
        guard let next = calendar.date(byAdding: .day, value: daysUntilNextWeek, to: date) else {
            return nil
        }
        return applyTimeOfDay(to: next, calendar: calendar)
    }

    /// 매월 반복의 다음 occurrence
    private func nextMonthlyOccurrence(after date: Date, calendar: Calendar) -> Date? {
        // interval개월 후
        guard let next = calendar.date(byAdding: .month, value: interval, to: date) else {
            return nil
        }
        return applyTimeOfDay(to: next, calendar: calendar)
    }

    /// timeOfDay 적용
    private func applyTimeOfDay(to date: Date, calendar: Calendar) -> Date {
        guard let time = timeOfDay else { return date }

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0

        return calendar.date(from: components) ?? date
    }
}

// MARK: - Description

extension RecurrenceRule {
    /// 사용자 표시용 요약 (KR)
    public var summaryKR: String {
        var parts: [String] = []

        if interval > 1 {
            parts.append("\(interval)")
        }

        switch kind {
        case .daily:
            parts.append(interval > 1 ? "일마다" : "매일")
        case .weekly:
            if weekdays.count == 5 &&
               weekdays.contains(.monday) &&
               weekdays.contains(.tuesday) &&
               weekdays.contains(.wednesday) &&
               weekdays.contains(.thursday) &&
               weekdays.contains(.friday) {
                parts.append(interval > 1 ? "주마다 평일" : "평일")
            } else {
                let sortedDays = weekdays.sorted().map { $0.shortLabelKR }.joined(separator: ",")
                parts.append(interval > 1 ? "주마다 \(sortedDays)" : "매주 \(sortedDays)")
            }
        case .monthly:
            parts.append(interval > 1 ? "개월마다" : "매월")
        }

        if let time = timeOfDay {
            parts.append(time.formattedKR)
        }

        return parts.joined(separator: " ")
    }

    /// 사용자 표시용 요약 (EN)
    public var summaryEN: String {
        var parts: [String] = []

        switch kind {
        case .daily:
            parts.append(interval > 1 ? "Every \(interval) days" : "Daily")
        case .weekly:
            if weekdays.count == 5 &&
               weekdays.contains(.monday) &&
               weekdays.contains(.tuesday) &&
               weekdays.contains(.wednesday) &&
               weekdays.contains(.thursday) &&
               weekdays.contains(.friday) {
                parts.append(interval > 1 ? "Every \(interval) weeks, weekdays" : "Weekdays")
            } else {
                let sortedDays = weekdays.sorted().map { $0.shortLabelEN }.joined(separator: ", ")
                parts.append(interval > 1 ? "Every \(interval) weeks on \(sortedDays)" : "Weekly on \(sortedDays)")
            }
        case .monthly:
            parts.append(interval > 1 ? "Every \(interval) months" : "Monthly")
        }

        if let time = timeOfDay {
            parts.append("at \(time.formatted12Hour)")
        }

        return parts.joined(separator: " ")
    }
}
