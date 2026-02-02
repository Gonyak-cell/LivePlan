import Foundation

/// App Group 컨테이너 관리
/// - architecture.md C2 준수: Shared Container를 단일 진실원천으로
public struct AppGroupContainer: Sendable {
    public static let groupIdentifier = "group.com.liveplan.shared"

    /// 공유 컨테이너 URL
    public static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        )
    }

    /// 데이터 파일 URL
    public static var dataFileURL: URL? {
        containerURL?.appendingPathComponent("data.json")
    }

    /// 백업 파일 URL
    public static var backupFileURL: URL? {
        containerURL?.appendingPathComponent("data.backup.json")
    }

    /// 컨테이너 사용 가능 여부
    public static var isAvailable: Bool {
        containerURL != nil
    }
}

// MARK: - Fallback for Testing

extension AppGroupContainer {
    /// 테스트/개발용 로컬 디렉토리
    public static var fallbackURL: URL {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documentsPath.appendingPathComponent("LivePlan")
    }

    /// 테스트/개발용 데이터 파일 URL
    public static var fallbackDataFileURL: URL {
        fallbackURL.appendingPathComponent("data.json")
    }

    /// 실제 사용할 데이터 파일 URL (컨테이너 우선, 폴백 지원)
    public static var effectiveDataFileURL: URL {
        dataFileURL ?? fallbackDataFileURL
    }

    /// 디렉토리 생성 보장
    public static func ensureDirectoryExists() throws {
        let url = containerURL ?? fallbackURL
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
