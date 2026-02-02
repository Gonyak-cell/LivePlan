import Foundation

/// 태그/라벨 엔티티
/// - data-model.md A3 준수
/// - 태스크의 다대다 분류
public struct Tag: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var colorToken: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        colorToken: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorToken = colorToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Name Normalization

extension Tag {
    /// 정규화된 이름 (대소문자 무시 비교용)
    /// - data-model.md: name은 대소문자 무시 유니크 권장
    public var normalizedName: String {
        name.lowercased().trimmingCharacters(in: .whitespaces)
    }

    /// 대소문자 무시 이름 비교
    public func nameMatches(_ other: String) -> Bool {
        normalizedName == other.lowercased().trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Display

extension Tag {
    /// 표시용 라벨 (# 포함)
    public var displayLabel: String {
        "#\(name)"
    }
}

// MARK: - Parsing

extension Tag {
    /// QuickAdd 파싱용 (#tag 형식)
    /// - product-decisions.md 5 준수
    /// - "#" 접두어 제거 후 이름 반환
    public static func parseTagName(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }

        let name = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }

        return name
    }
}

// MARK: - Color Token

extension Tag {
    /// 기본 색상 토큰 목록 (Phase 2 확장 대비)
    public static let defaultColorTokens = [
        "red", "orange", "yellow", "green", "blue", "purple", "pink", "gray"
    ]

    /// 색상 토큰이 유효한지 확인
    public var hasValidColorToken: Bool {
        guard let token = colorToken else { return false }
        return Self.defaultColorTokens.contains(token)
    }
}

// MARK: - Array Extensions

extension Array where Element == Tag {
    /// 이름으로 태그 찾기 (대소문자 무시)
    public func find(byName name: String) -> Tag? {
        first { $0.nameMatches(name) }
    }

    /// 이름 중복 확인 (대소문자 무시)
    public func containsName(_ name: String) -> Bool {
        find(byName: name) != nil
    }

    /// ID 목록으로 필터링
    public func filter(byIds ids: Set<String>) -> [Tag] {
        filter { ids.contains($0.id) }
    }

    /// 이름순 정렬
    public func sortedByName() -> [Tag] {
        sorted { $0.normalizedName < $1.normalizedName }
    }
}
