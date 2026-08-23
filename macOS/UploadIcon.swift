import Foundation

/// The symbol in the menu bar, and how long it stays there.
enum UploadIcon {
    case idle
    case dragging
    case uploading
    case success
    case failure

    var systemName: String {
        switch self {
        case .idle: "cloud.fill"
        case .dragging: "cloud"
        case .uploading: "arrow.up"
        case .success: "checkmark"
        case .failure: "xmark"
        }
    }

    /// A result shows for a moment, then the icon goes back to idle.
    var isTemporary: Bool {
        switch self {
        case .success, .failure: true
        case .idle, .dragging, .uploading: false
        }
    }

    static let temporaryDuration: TimeInterval = 2.5
}
