import Foundation

extension FileUploader {
    func uploadAsync() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = AsyncUploadDelegate(continuation: continuation)
            self.delegate = delegate
            self.upload()
        }
    }
}

private class AsyncUploadDelegate: UploadDelegate {
    private var continuation: CheckedContinuation<URL, Error>?

    init(continuation: CheckedContinuation<URL, Error>) {
        self.continuation = continuation
    }

    func uploading() {}

    func uploaded(url: URL) {
        continuation?.resume(returning: url)
        continuation = nil
    }

    func error(error: String) {
        continuation?.resume(throwing: NSError(domain: "FileUploader", code: 1, userInfo: [NSLocalizedDescriptionKey: error]))
        continuation = nil
    }
}
