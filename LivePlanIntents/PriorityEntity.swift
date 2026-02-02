import AppIntents
import AppCore

/// 우선순위 AppEnum (단축어/인텐트용)
/// - product-decisions.md 3.2: P1~P4 (기본 P4)
@available(iOS 17.0, *)
struct PriorityEntity: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "우선순위"

    static var caseDisplayRepresentations: [PriorityEntity: DisplayRepresentation] = [
        .p1: DisplayRepresentation(title: "P1", subtitle: "가장 높음"),
        .p2: DisplayRepresentation(title: "P2", subtitle: "높음"),
        .p3: DisplayRepresentation(title: "P3", subtitle: "보통"),
        .p4: DisplayRepresentation(title: "P4", subtitle: "낮음")
    ]

    case p1
    case p2
    case p3
    case p4

    var toPriority: Priority {
        switch self {
        case .p1: return .p1
        case .p2: return .p2
        case .p3: return .p3
        case .p4: return .p4
        }
    }
}
