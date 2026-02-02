import Foundation

/// 스키마 버전 정의
/// - Phase 1: Version 1
/// - Phase 2: Version 2 (Sections/Tags/Priority/WorkflowState 추가)
public enum SchemaVersion: Int, Comparable {
    case v1 = 1
    case v2 = 2

    public static let current: SchemaVersion = .v2

    public static func < (lhs: SchemaVersion, rhs: SchemaVersion) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
