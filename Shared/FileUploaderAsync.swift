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

    private var selfReference: AsyncUploadDelegate?

    init(continuation: CheckedContinuation<URL, Error>) {
        self.continuation = continuation
        self.selfReference = self
    }

    func uploading() {}

    func uploaded(url: URL) {
        continuation?.resume(returning: url)
        finish()
    }

    func error(error: String) {
        continuation?.resume(throwing: NSError(domain: "FileUploader", code: 1, userInfo: [NSLocalizedDescriptionKey: error]))
        finish()
    }

    private func finish() {
        continuation = nil
        selfReference = nil
    }
}
