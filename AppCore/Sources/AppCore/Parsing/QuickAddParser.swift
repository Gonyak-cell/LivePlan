import Foundation

/// QuickAdd 빠른 입력 파서
/// - product-decisions.md 5 준수
/// - architecture.md: AppCore에만 위치 (SwiftUI 의존 없음)
/// - 파싱 실패 시 제목만 반환 (크래시 금지)
///
/// ## 지원 토큰
/// - 우선순위: p1, P2, p3, p4
/// - 태그: #tag, #work (다중 지원)
/// - 프로젝트: @project
/// - 섹션: /section, ::section
/// - 날짜: 오늘, 내일, 모레, 월요일 등
/// - 시간: 오후 3시, 3pm, 15:30 등
public struct QuickAddParser: Sendable {

    private let dateTokenParser: DateTokenParser
    private let referenceDate: Date
    private let timeZone: TimeZone

    public init(
        referenceDate: Date = Date(),
        timeZone: TimeZone = .current
    ) {
        self.referenceDate = referenceDate
        self.timeZone = timeZone
        self.dateTokenParser = DateTokenParser(
            referenceDate: referenceDate,
            timeZone: timeZone
        )
    }

    /// 입력 문자열 파싱
    /// - Parameter input: "내일 오후 3시 p1 #work @프로젝트명 회의" 형태
    /// - Returns: ParsedTask (실패 시에도 title 포함)
    public func parse(_ input: String) -> ParsedTask {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .titleOnly("")
        }

        var remainingText = trimmed
        var dueDate: Date?
        var timeOfDay: TimeOfDayValue?
        var priority: Priority?
        var tagNames: [String] = []
        var projectName: String?
        var sectionName: String?

        // 1. 우선순위 토큰 (p1, P2 등)
        if let (parsed, remaining) = extractPriority(from: remainingText) {
            priority = parsed
            remainingText = remaining
        }

        // 2. 태그 토큰 (#tag)
        let (parsedTags, afterTags) = extractTags(from: remainingText)
        tagNames = parsedTags
        remainingText = afterTags

        // 3. 프로젝트 토큰 (@project)
        if let (parsed, remaining) = extractProject(from: remainingText) {
            projectName = parsed
            remainingText = remaining
        }

        // 4. 섹션 토큰 (/section 또는 ::section)
        if let (parsed, remaining) = extractSection(from: remainingText) {
            sectionName = parsed
            remainingText = remaining
        }

        // 5. 날짜/시간 토큰 (내일, 오후 3시 등)
        let dateResult = dateTokenParser.parse(remainingText)
        dueDate = dateResult.date
        if let time = dateResult.time {
            timeOfDay = TimeOfDayValue(hour: time.hour, minute: time.minute)
        }
        remainingText = dateResult.remainingText

        // 남은 텍스트가 제목
        let finalTitle = cleanupTitle(remainingText)

        // 제목이 비어있으면 원문 사용
        return ParsedTask(
            title: finalTitle.isEmpty ? trimmed : finalTitle,
            dueDate: dueDate,
            timeOfDay: timeOfDay,
            priority: priority,
            tagNames: tagNames,
            projectName: projectName,
            sectionName: sectionName
        )
    }

    // MARK: - Private Helpers

    private func cleanupTitle(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // 중복 공백 제거
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        return result
    }
}

// MARK: - Token Extraction Methods

extension QuickAddParser {

    /// 우선순위 토큰 추출 (p1, P2, p3, p4)
    func extractPriority(from text: String) -> (Priority, String)? {
        // 정규식: 단어 경계에서 p1~p4
        let pattern = #"(?i)\b(p[1-4])\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ),
              let tokenRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let token = String(text[tokenRange])
        guard let priority = Priority(parsing: token) else {
            return nil
        }

        // 토큰 제거
        var remaining = text
        if let fullRange = Range(match.range, in: text) {
            remaining.removeSubrange(fullRange)
        }

        return (priority, remaining)
    }

    /// 태그 토큰들 추출 (#tag1 #tag2)
    func extractTags(from text: String) -> ([String], String) {
        var remaining = text
        var tagNames: [String] = []

        // 정규식: #으로 시작하는 연속 문자 (공백/특수문자로 종료)
        let pattern = #"#([^\s#@/：:]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return ([], text)
        }

        let matches = regex.matches(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        )

        // 역순으로 제거 (인덱스 유지)
        for match in matches.reversed() {
            if let nameRange = Range(match.range(at: 1), in: remaining) {
                let tagName = String(remaining[nameRange])
                if !tagName.isEmpty {
                    tagNames.insert(tagName, at: 0)  // 원래 순서 유지
                }
            }
            if let fullRange = Range(match.range, in: remaining) {
                remaining.removeSubrange(fullRange)
            }
        }

        return (tagNames, remaining)
    }

    /// 프로젝트 토큰 추출 (@project)
    func extractProject(from text: String) -> (String, String)? {
        // 정규식: @으로 시작하는 연속 문자
        let pattern = #"@([^\s@#/：:]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ),
              let nameRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let projectName = String(text[nameRange])
        guard !projectName.isEmpty else { return nil }

        var remaining = text
        if let fullRange = Range(match.range, in: text) {
            remaining.removeSubrange(fullRange)
        }

        return (projectName, remaining)
    }

    /// 섹션 토큰 추출 (/section 또는 ::section)
    func extractSection(from text: String) -> (String, String)? {
        // 정규식: / 또는 :: 로 시작 (단, URL 형태가 아닌 경우만)
        // "https://" 같은 URL 패턴 제외
        let pattern = #"(?<![a-zA-Z])(?:/|::)([^\s@#/：:]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ),
              let nameRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let sectionName = String(text[nameRange])
        guard !sectionName.isEmpty else { return nil }

        var remaining = text
        if let fullRange = Range(match.range, in: text) {
            remaining.removeSubrange(fullRange)
        }

        return (sectionName, remaining)
    }
}
