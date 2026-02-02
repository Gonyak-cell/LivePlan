import Foundation

/// 태스크 우선순위
/// - data-model.md A4 준수
/// - P1 (가장 높음) ~ P4 (가장 낮음, 기본값)
/// - 잠금화면 선정에서 P1 우선 노출 (lockscreen.md G4)
public enum Priority: Int, Codable, CaseIterable, Sendable, Comparable {
    case p1 = 1
    case p2 = 2
    case p3 = 3
    case p4 = 4

    /// 기본값 (P4)
    public static let defaultPriority: Priority = .p4

    /// Comparable: 숫자가 낮을수록 우선순위 높음
    public static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Description

extension Priority {
    /// 사용자 표시용 라벨 (짧은 형태)
    public var label: String {
        switch self {
        case .p1: return "P1"
        case .p2: return "P2"
        case .p3: return "P3"
        case .p4: return "P4"
        }
    }

    /// 사용자 표시용 설명 (KR)
    public var descriptionKR: String {
        switch self {
        case .p1: return "가장 높음"
        case .p2: return "높음"
        case .p3: return "보통"
        case .p4: return "낮음"
        }
    }

    /// 사용자 표시용 설명 (EN)
    public var descriptionEN: String {
        switch self {
        case .p1: return "Highest"
        case .p2: return "High"
        case .p3: return "Medium"
        case .p4: return "Low"
        }
    }
}

// MARK: - Parsing

extension Priority {
    /// QuickAdd 파싱용 (product-decisions.md 5)
    /// - "p1", "P1" 등 파싱
    public init?(parsing input: String) {
        let lowercased = input.lowercased().trimmingCharacters(in: .whitespaces)
        switch lowercased {
        case "p1": self = .p1
        case "p2": self = .p2
        case "p3": self = .p3
        case "p4": self = .p4
        default: return nil
        }
    }
}
