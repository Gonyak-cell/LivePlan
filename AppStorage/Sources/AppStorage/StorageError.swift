import Foundation

/// 저장소 에러
/// - error-and-messaging.md B 준수
public enum StorageError: Error, LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String, Error)
    case encodingFailed(String, Error)
    case writeFailed(String, Error)
    case containerNotAvailable
    case migrationFailed(from: Int, to: Int, Error)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .decodingFailed(let path, let error):
            return "Failed to decode file at \(path): \(error.localizedDescription)"
        case .encodingFailed(let path, let error):
            return "Failed to encode data for \(path): \(error.localizedDescription)"
        case .writeFailed(let path, let error):
            return "Failed to write file at \(path): \(error.localizedDescription)"
        case .containerNotAvailable:
            return "App Group container is not available"
        case .migrationFailed(let from, let to, let error):
            return "Migration failed from v\(from) to v\(to): \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown storage error: \(error.localizedDescription)"
        }
    }
}
