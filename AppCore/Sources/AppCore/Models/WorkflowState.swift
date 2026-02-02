import Foundation

/// 태스크 워크플로 상태 (보드 뷰용)
/// - data-model.md A4 준수
/// - todo (기본) / doing / done
/// - 잠금화면 선정에서 doing 우선 노출 (lockscreen.md G1)
public enum WorkflowState: String, Codable, CaseIterable, Sendable {
    /// 할 일 (기본값)
    case todo

    /// 진행 중
    case doing

    /// 완료
    case done

    /// 기본값 (todo)
    public static let defaultState: WorkflowState = .todo
}

// MARK: - Description

extension WorkflowState {
    /// 사용자 표시용 설명 (KR)
    public var descriptionKR: String {
        switch self {
        case .todo: return "할 일"
        case .doing: return "진행 중"
        case .done: return "완료"
        }
    }

    /// 사용자 표시용 설명 (EN)
    public var descriptionEN: String {
        switch self {
        case .todo: return "To Do"
        case .doing: return "In Progress"
        case .done: return "Done"
        }
    }
}

// MARK: - Convenience

extension WorkflowState {
    /// 완료 상태인지 여부
    public var isCompleted: Bool {
        self == .done
    }

    /// 활성 상태인지 여부 (todo 또는 doing)
    public var isActive: Bool {
        self != .done
    }

    /// 진행 중인지 여부
    public var isInProgress: Bool {
        self == .doing
    }
}

// MARK: - Board Order

extension WorkflowState {
    /// 보드 뷰에서의 컬럼 순서 (0: todo, 1: doing, 2: done)
    public var boardOrder: Int {
        switch self {
        case .todo: return 0
        case .doing: return 1
        case .done: return 2
        }
    }

    /// 보드 뷰 컬럼 순서대로 정렬된 케이스
    public static var boardOrdered: [WorkflowState] {
        [.todo, .doing, .done]
    }
}
