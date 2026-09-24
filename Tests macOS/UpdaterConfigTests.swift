import XCTest

class UpdaterConfigTests: XCTestCase {
    private let info = Bundle.main.infoDictionary ?? [:]

    func testFeedIsHTTPS() throws {
        let feed = try XCTUnwrap(info["SUFeedURL"] as? String)
        XCTAssertEqual(URL(string: feed)?.scheme, "https")
    }

    func testPublicKeyIsEd25519() throws {
        let key = try XCTUnwrap(info["SUPublicEDKey"] as? String)
        XCTAssertEqual(Data(base64Encoded: key)?.count, 32)
    }

    func testSandboxCanLaunchInstaller() {
        XCTAssertEqual(info["SUEnableInstallerLauncherService"] as? Bool, true)
    }

    func testBuildNumberIsAnInteger() throws {
        let build = try XCTUnwrap(info["CFBundleVersion"] as? String)
        XCTAssertNotNil(Int(build), "Sparkle compares the build number")
    }
}
