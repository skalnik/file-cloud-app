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

    func testFormDataWithNonexistentFile() {
        let fakeFile = URL(fileURLWithPath: "/nonexistent/file.txt")
        let formData = uploader.formData(boundary: "boundary", fileURL: fakeFile)
        XCTAssertNil(formData)
    }
}
