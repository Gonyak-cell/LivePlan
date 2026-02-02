// AppCore - Domain Logic Module
// architecture.md 준수: UI 프레임워크 import 금지

// MARK: - Models
// @_exported import 대신 public으로 노출

// MARK: - Version Info
public enum AppCoreVersion {
    public static let major = 1
    public static let minor = 0
    public static let patch = 0
    public static var string: String { "\(major).\(minor).\(patch)" }
}
