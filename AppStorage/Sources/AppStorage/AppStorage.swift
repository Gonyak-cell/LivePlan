// AppStorage - Persistence Module
// architecture.md D2 준수: 저장 구현만 담당

// MARK: - Version Info
public enum AppStorageVersion {
    public static let major = 1
    public static let minor = 0
    public static let patch = 0
    public static var string: String { "\(major).\(minor).\(patch)" }
}
