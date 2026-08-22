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
        uploader.fileURL = URL(fileURLWithPath: "/tmp/test.txt")
        uploader.upload()

        XCTAssertEqual(delegate.errorMessage, "Server URL is not configured")
        XCTAssertTrue(delegate.uploadingCalled)
    }

    func testUploadWithNilFileURL() {
        uploader.fileURL = nil
        uploader.upload()

        XCTAssertEqual(delegate.errorMessage, "No file selected")
    }

    func testFormDataWithKnownMimeType() throws {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test.png")
        let testData = Data("fakepng".utf8)
        try testData.write(to: tempFile)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let boundary = "test-boundary"
        let formData = uploader.formData(boundary: boundary, fileURL: tempFile)

        XCTAssertNotNil(formData)
        let formString = String(data: formData!, encoding: .utf8)!
        XCTAssertTrue(formString.contains("--test-boundary\r\n"))
        XCTAssertTrue(formString.contains("Content-Disposition: form-data; name=\"file\"; filename=\"test.png\""))
        XCTAssertTrue(formString.contains("Content-Type: image/png"))
        XCTAssertTrue(formString.contains("--test-boundary--"))
    }

    func testFormDataWithUnknownMimeType() throws {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test.unknownext")
        let testData = Data("hello".utf8)
        try testData.write(to: tempFile)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let boundary = "test-boundary"
        let formData = uploader.formData(boundary: boundary, fileURL: tempFile)

        XCTAssertNotNil(formData)
        let formString = String(data: formData!, encoding: .utf8)!
        XCTAssertTrue(formString.contains("Content-Disposition: form-data;"))
        XCTAssertFalse(formString.contains("Content-Type:"))
        // Should still have proper header/body separator
        XCTAssertTrue(formString.contains("\r\n\r\n"))
    }

    func testAuthHeaderFormat() {
        uploader.username = "user"
        uploader.password = "pass"
        uploader.serverURL = URL(string: "https://example.com")

        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")
        try? Data("hello".utf8).write(to: tempFile)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        uploader.fileURL = tempFile

        // The expected base64 of "user:pass"
        let expected = Data("user:pass".utf8).base64EncodedString()
        XCTAssertEqual(expected, "dXNlcjpwYXNz")
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

    func testUnauthorizedResponseReportsCredentials() {
        // The server sends HTML, not JSON, with a 401.
        let data = Data("<html>Unauthorized</html>".utf8)
        uploader.completionHandler(data: data, response: httpResponse(401), error: nil)

        XCTAssertEqual(delegate.errorMessage, "Check your username and password")
        XCTAssertNil(delegate.uploadedURL)
    }

    func testNotFoundResponseReportsTheURL() {
        uploader.completionHandler(data: Data(), response: httpResponse(404), error: nil)

        XCTAssertEqual(delegate.errorMessage, "The server URL is not correct")
    }

    func testServerErrorReportsTheStatusCode() {
        uploader.completionHandler(data: Data(), response: httpResponse(500), error: nil)

        XCTAssertEqual(delegate.errorMessage, "The server returned an error (HTTP 500)")
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

    func testFormDataWithNonexistentFile() {
        let fakeFile = URL(fileURLWithPath: "/nonexistent/file.txt")
        let formData = uploader.formData(boundary: "boundary", fileURL: fakeFile)
        XCTAssertNil(formData)
    }
}
