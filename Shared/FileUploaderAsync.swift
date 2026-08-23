import Foundation

extension FileUploader {
    /// The upload task holds the completion, and through it this uploader,
    /// until the server answers. Nothing else must keep them alive.
    func uploadAsync(fileURL: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            upload(fileURL: fileURL) { result in
                continuation.resume(with: result)
            }
        }
    }
}
