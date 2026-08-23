import XCTest
@testable import File_Cloud

class BasicAuthTests: XCTestCase {
    private func header(username: String?, password: String?) -> String? {
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.setBasicAuth(username: username, password: password)
        return request.value(forHTTPHeaderField: "Authorization")
    }

    func testFullCredentialsMakeTheHeader() {
        XCTAssertEqual(header(username: "user", password: "pass"), "Basic dXNlcjpwYXNz")
    }

    func testAHalfFilledLoginAddsNoHeader() {
        XCTAssertNil(header(username: "user", password: ""))
        XCTAssertNil(header(username: "", password: "pass"))
        XCTAssertNil(header(username: "user", password: nil))
        XCTAssertNil(header(username: nil, password: "pass"))
        XCTAssertNil(header(username: nil, password: nil))
    }

    func testNonASCIICredentialsUseUTF8() {
        // Data(_.utf8) cannot fail, unlike data(using:), which returns nil.
        XCTAssertEqual(header(username: "üser", password: "pä55"),
                       "Basic " + Data("üser:pä55".utf8).base64EncodedString())
    }
}
