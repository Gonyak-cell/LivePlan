import Foundation

/// QuickAdd 파싱 결과 DTO
/// - product-decisions.md 5 준수
/// - 파싱 실패 시에도 title만 반환 (크래시/실패 금지)
/// - architecture.md: AppCore에만 위치 (SwiftUI 의존 없음)
public struct ParsedTask: Equatable, Sendable {

    /// 파싱 후 남은 제목 (토큰 제거됨)
    public let title: String

    /// 파싱된 마감일
    public let dueDate: Date?

    /// 파싱된 시간 (hour: 0-23, minute: 0-59)
    public let timeOfDay: TimeOfDayValue?

    /// 파싱된 우선순위 (P1~P4)
    public let priority: Priority?

    /// 파싱된 태그 이름들 (ID 아님, 나중에 매칭)
    public let tagNames: [String]

    /// 파싱된 프로젝트 이름 (ID 아님, 나중에 매칭)
    public let projectName: String?

    /// 파싱된 섹션 이름 (ID 아님, 나중에 매칭)
    public let sectionName: String?

    /// 파싱 성공 여부 (1개 이상 토큰 파싱됨)
    public var hasAnyParsedTokens: Bool {
        dueDate != nil || timeOfDay != nil || priority != nil ||
        !tagNames.isEmpty || projectName != nil || sectionName != nil
    }

    public init(
        title: String,
        dueDate: Date? = nil,
        timeOfDay: TimeOfDayValue? = nil,
        priority: Priority? = nil,
        tagNames: [String] = [],
        projectName: String? = nil,
        sectionName: String? = nil
    ) {
        self.title = title
        self.dueDate = dueDate
        self.timeOfDay = timeOfDay
        self.priority = priority
        self.tagNames = tagNames
        self.projectName = projectName
        self.sectionName = sectionName
    }

    /// 실패 폴백: 원문 그대로 제목으로
    public static func titleOnly(_ text: String) -> ParsedTask {
        ParsedTask(title: text.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: - TimeOfDayValue

/// 시간 값 (튜플 대신 구조체 사용하여 Equatable/Sendable 준수)
public struct TimeOfDayValue: Equatable, Sendable {
    public let hour: Int    // 0-23
    public let minute: Int  // 0-59

    public init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }

    /// 24시간 형식 문자열 (HH:mm)
    public var formatted: String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// 한글 형식 (오전/오후 h시 m분)
    public var formattedKR: String {
        let period = hour < 12 ? "오전" : "오후"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        if minute == 0 {
            return "\(period) \(displayHour)시"
        } else {
            return "\(period) \(displayHour)시 \(minute)분"
        }
    }
}

// MARK: - Date Combination

extension ParsedTask {
    /// dueDate와 timeOfDay를 결합하여 최종 Date 반환
    /// - Parameter calendar: 사용할 캘린더 (기본 current)
    /// - Returns: 결합된 Date (timeOfDay가 없으면 dueDate 그대로)
    public func combinedDueDate(calendar: Calendar = .current) -> Date? {
        guard let date = dueDate else { return nil }
        guard let time = timeOfDay else { return date }

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = time.hour
        components.minute = time.minute

        return calendar.date(from: components) ?? date
    }
}
