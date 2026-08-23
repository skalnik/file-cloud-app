import XCTest
@testable import File_Cloud

class MockUploadDelegate: UploadDelegate {
    var errorMessage: String?
    var uploadedURL: URL?
    var uploadingCalled = false

    func error(error: String) {
        errorMessage = error
    }

    func uploaded(url: URL) {
        uploadedURL = url
    }

    func uploading() {
        uploadingCalled = true
    }
}

class FileUploaderTests: XCTestCase {
    var uploader: FileUploader!
    var delegate: MockUploadDelegate!

    override func setUp() {
        super.setUp()
        delegate = MockUploadDelegate()
        uploader = FileUploader(serverURL: URL(string: "https://example.com"),
                                username: nil,
                                password: nil)
        uploader.delegate = delegate
    }

    func testUploadWithNilServerURL() {
        uploader.serverURL = nil
        uploader.upload(fileURL: URL(fileURLWithPath: "/tmp/test.txt"))

        XCTAssertEqual(delegate.errorMessage, "Server URL is not configured")
        XCTAssertTrue(delegate.uploadingCalled)
    }

    /// The delegate and the completion must hear the same failure.
    func testUploadReportsFailureToTheCompletion() {
        uploader.serverURL = nil
        var result: Result<URL, Error>?

        uploader.upload(fileURL: URL(fileURLWithPath: "/tmp/test.txt")) { result = $0 }

        guard case .failure(let error)? = result else {
            return XCTFail("The completion must get a failure")
        }
        XCTAssertEqual(error.localizedDescription, "Server URL is not configured")
        XCTAssertEqual(delegate.errorMessage, error.localizedDescription)
    }

    func testSuccessReachesTheCompletion() {
        var result: Result<URL, Error>?
        let data = Data(#"{"url":"abc123.png"}"#.utf8)

        uploader.completionHandler(data: data, response: httpResponse(200), error: nil) { result = $0 }

        guard case .success(let url)? = result else {
            return XCTFail("The completion must get the URL")
        }
        XCTAssertEqual(url.absoluteString, "https://example.com/abc123.png")
        XCTAssertEqual(delegate.uploadedURL, url)
    }

    /// Makes the body file, reads it back, then removes it.
    private func bodyData(fileURL: URL, boundary: String = "test-boundary") throws -> Data {
        let bodyURL = try uploader.multipartBody(boundary: boundary, fileURL: fileURL)
        defer { try? FileManager.default.removeItem(at: bodyURL) }
        return try Data(contentsOf: bodyURL)
    }

    func testMultipartBodyWithKnownMimeType() throws {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test.png")
        try Data("fakepng".utf8).write(to: tempFile)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let formString = String(data: try bodyData(fileURL: tempFile), encoding: .utf8)!

        XCTAssertTrue(formString.contains("--test-boundary\r\n"))
        XCTAssertTrue(formString.contains("Content-Disposition: form-data; name=\"file\"; filename=\"test.png\""))
        XCTAssertTrue(formString.contains("Content-Type: image/png"))
        XCTAssertTrue(formString.contains("--test-boundary--"))
    }

    func testMultipartBodyWithUnknownMimeType() throws {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test.unknownext")
        try Data("hello".utf8).write(to: tempFile)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let formString = String(data: try bodyData(fileURL: tempFile), encoding: .utf8)!

        XCTAssertTrue(formString.contains("Content-Disposition: form-data;"))
        XCTAssertFalse(formString.contains("Content-Type:"))
        // Should still have proper header/body separator
        XCTAssertTrue(formString.contains("\r\n\r\n"))
    }

    func testMultipartBodyKeepsFileBytesExact() throws {
        // Larger than the 1 MB chunk, and not a multiple of it.
        let fileBytes = Data((0..<(3 * 1024 * 1024 + 7)).map { UInt8($0 % 251) })
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("big.unknownext")
        try fileBytes.write(to: tempFile)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let body = try bodyData(fileURL: tempFile)

        let header = Data("--test-boundary\r\nContent-Disposition: form-data; name=\"file\"; filename=\"big.unknownext\"\r\n\r\n".utf8)
        let footer = Data("\r\n--test-boundary--\r\n".utf8)

        XCTAssertEqual(body.count, header.count + fileBytes.count + footer.count)
        XCTAssertEqual(body.prefix(header.count), header)
        XCTAssertEqual(body.suffix(footer.count), footer)
        XCTAssertEqual(body.dropFirst(header.count).dropLast(footer.count), fileBytes)
    }

    /// Counts the body files that multipartBody leaves in the temporary directory.
    private func bodyFileCount() throws -> Int {
        try FileManager.default
            .contentsOfDirectory(atPath: FileManager.default.temporaryDirectory.path)
            .filter { $0.hasPrefix("upload-") }
            .count
    }

    func testMultipartBodyRemovesTheFileWhenTheSourceIsMissing() throws {
        let before = try bodyFileCount()

        XCTAssertThrowsError(try uploader.multipartBody(boundary: "b",
                                                        fileURL: URL(fileURLWithPath: "/nonexistent/file.txt")))

        XCTAssertEqual(try bodyFileCount(), before, "A failed body must leave no file behind")
    }


    func testKeychainRoundTrip() {
        let account = "test-keychain-round-trip"

        // Clean slate
        Keychain.delete(account: account)
        XCTAssertNil(Keychain.read(account: account))

        // Save and read
        Keychain.save(account: account, password: "s3cret")
        XCTAssertEqual(Keychain.read(account: account), "s3cret")

        // Overwrite
        Keychain.save(account: account, password: "updated")
        XCTAssertEqual(Keychain.read(account: account), "updated")

        // Delete
        Keychain.delete(account: account)
        XCTAssertNil(Keychain.read(account: account))
    }

    // MARK: - Response handling

    private func httpResponse(_ statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://example.com")!,
                        statusCode: statusCode,
                        httpVersion: "HTTP/1.1",
                        headerFields: nil)!
    }

    func testSuccessResponseMakesTheURL() {
        let data = Data(#"{"url":"abc123.png"}"#.utf8)
        uploader.completionHandler(data: data, response: httpResponse(200), error: nil)

        XCTAssertEqual(delegate.uploadedURL?.absoluteString, "https://example.com/abc123.png")
        XCTAssertNil(delegate.errorMessage)
    }

    func testFailureStatusCodesReportAUsefulMessage() {
        // The server sends HTML, not JSON, when it rejects the upload.
        let data = Data("<html>Unauthorized</html>".utf8)
        let cases: [(code: Int, message: String)] = [
            (401, "Check your username and password"),
            (403, "Check your username and password"),
            (404, "The server URL is not correct"),
            (500, "The server returned an error (HTTP 500)"),
        ]

        for (code, message) in cases {
            delegate = MockUploadDelegate()
            uploader.delegate = delegate

            uploader.completionHandler(data: data, response: httpResponse(code), error: nil)

            XCTAssertEqual(delegate.errorMessage, message, "status \(code)")
            XCTAssertNil(delegate.uploadedURL, "status \(code)")
        }
    }

    func testTransportErrorUsesTheLocalizedDescription() {
        let error = NSError(domain: NSURLErrorDomain,
                            code: NSURLErrorNotConnectedToInternet,
                            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])
        uploader.completionHandler(data: nil, response: nil, error: error)

        XCTAssertEqual(delegate.errorMessage, "The Internet connection appears to be offline.")
    }

    func testMalformedJSONReportsAReadableError() {
        let data = Data("not json".utf8)
        uploader.completionHandler(data: data, response: httpResponse(200), error: nil)

        XCTAssertEqual(delegate.errorMessage, "Could not read the response of the server")
    }

    func testMissingResponseIsAnError() {
        uploader.completionHandler(data: Data(), response: nil, error: nil)

        XCTAssertEqual(delegate.errorMessage, "No response from the server")
    }

    // MARK: - Delegate lifetime

    func testDelegateIsWeak() {
        var strongDelegate: MockUploadDelegate? = MockUploadDelegate()
        uploader.delegate = strongDelegate
        XCTAssertNotNil(uploader.delegate)

        strongDelegate = nil

        XCTAssertNil(uploader.delegate, "FileUploader must not keep its delegate alive")
    }

    func testMultipartBodyThrowsForANonexistentFile() {
        let fakeFile = URL(fileURLWithPath: "/nonexistent/file.txt")
        XCTAssertThrowsError(try uploader.multipartBody(boundary: "boundary", fileURL: fakeFile))
    }
}
