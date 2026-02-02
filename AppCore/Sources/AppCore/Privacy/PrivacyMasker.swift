import Foundation

/// 프라이버시 마스킹 유틸리티
/// - product-decisions.md 2.2/2.3 준수
public struct PrivacyMasker: Sendable {
    public init() {}

    /// 태스크 제목 마스킹
    /// - Parameters:
    ///   - title: 원본 제목
    ///   - index: 순서 (1-based)
    ///   - privacyMode: 프라이버시 모드
    ///   - maxLength: 최대 길이 (visible 모드용)
    public func maskTaskTitle(
        _ title: String,
        index: Int,
        privacyMode: PrivacyMode,
        maxLength: Int = 24
    ) -> String {
        switch privacyMode {
        case .visible:
            return truncate(title, maxLength: maxLength)
        case .masked:
            return "할 일 \(index)"
        case .hidden:
            return ""
        }
    }

    /// 프로젝트 제목 마스킹
    /// - Parameters:
    ///   - title: 원본 제목
    ///   - privacyMode: 프라이버시 모드
    ///   - maxLength: 최대 길이 (visible 모드용)
    public func maskProjectTitle(
        _ title: String,
        privacyMode: PrivacyMode,
        maxLength: Int = 18
    ) -> String {
        switch privacyMode {
        case .visible:
            return truncate(title, maxLength: maxLength)
        case .masked, .hidden:
            return "프로젝트"
        }
    }

    /// 인텐트 성공 메시지 생성
    /// - intents.md 메시지 규칙 준수
    public func intentSuccessMessage(
        action: IntentAction,
        taskTitle: String?,
        privacyMode: PrivacyMode
    ) -> String {
        switch action {
        case .complete:
            switch privacyMode {
            case .visible:
                if let title = taskTitle {
                    return "완료: \(truncate(title, maxLength: 18))"
                }
                return "완료했습니다"
            case .masked, .hidden:
                return "완료했습니다"
            }

        case .add:
            switch privacyMode {
            case .visible:
                if let title = taskTitle {
                    return "추가: \(truncate(title, maxLength: 18))"
                }
                return "추가했습니다"
            case .masked, .hidden:
                return "추가했습니다"
            }

        case .refresh:
            return "갱신했습니다"

        case .start:
            switch privacyMode {
            case .visible:
                if let title = taskTitle {
                    return "시작: \(truncate(title, maxLength: 18))"
                }
                return "시작했습니다"
            case .masked, .hidden:
                return "시작했습니다"
            }
        }
    }

    /// 인텐트 실패 메시지 생성
    public func intentFailureMessage(reason: IntentFailureReason) -> String {
        switch reason {
        case .noTaskToComplete:
            return "완료할 항목이 없습니다"
        case .noTaskToStart:
            return "시작할 항목이 없습니다"
        case .projectNotFound:
            return "프로젝트를 찾을 수 없습니다"
        case .emptyInput:
            return "내용을 입력해주세요"
        case .loadFailed:
            return "데이터를 불러오지 못했습니다"
        }
    }

    /// 문자열 잘라내기 (말줄임)
    private func truncate(_ string: String, maxLength: Int) -> String {
        guard string.count > maxLength else { return string }
        let endIndex = string.index(string.startIndex, offsetBy: maxLength - 1)
        return String(string[..<endIndex]) + "…"
    }
}

// MARK: - Intent Types

public enum IntentAction: Sendable {
    case complete
    case add
    case refresh
    case start
}

public enum IntentFailureReason: Sendable {
    case noTaskToComplete
    case noTaskToStart
    case projectNotFound
    case emptyInput
    case loadFailed
}
