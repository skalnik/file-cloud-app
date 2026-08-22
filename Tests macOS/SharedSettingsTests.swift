import XCTest
@testable import File_Cloud

class SharedSettingsTests: XCTestCase {
    var suiteName: String!
    var defaults: UserDefaults!
    var account: String!

    /// Each test gets its own defaults suite and its own Keychain account, so
    /// no test can read or overwrite the real settings of the developer.
    override func setUp() {
        super.setUp()
        suiteName = "test.file-cloud.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        account = "test-settings-\(UUID().uuidString)"
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        Keychain.delete(account: account)
        super.tearDown()
    }

    private func makeSettings() -> SharedSettings {
        SharedSettings(defaults: defaults, keychainAccount: account)
    }

    func testEmptyStoreGivesEmptyValues() {
        let settings = makeSettings()

        XCTAssertEqual(settings.serverURL, "")
        XCTAssertEqual(settings.username, "")
        XCTAssertFalse(settings.uploadOnEnter)
    }

    func testValuesPersistToTheStore() {
        let settings = makeSettings()

        settings.serverURL = "https://cloud.example.com"
        settings.username = "user"
        settings.uploadOnEnter = true

        XCTAssertEqual(defaults.string(forKey: "serverURL"), "https://cloud.example.com")
        XCTAssertEqual(defaults.string(forKey: "username"), "user")
        XCTAssertTrue(defaults.bool(forKey: "uploadOnEnter"))
    }

    func testNewInstanceReadsTheStoredValues() {
        defaults.set("https://cloud.example.com", forKey: "serverURL")
        defaults.set("user", forKey: "username")
        defaults.set(true, forKey: "uploadOnEnter")

        let settings = makeSettings()

        XCTAssertEqual(settings.serverURL, "https://cloud.example.com")
        XCTAssertEqual(settings.username, "user")
        XCTAssertTrue(settings.uploadOnEnter)
    }

    func testPasswordGoesToTheKeychainAndNotToTheStore() {
        let settings = makeSettings()

        settings.password = "s3cret"

        XCTAssertEqual(Keychain.read(account: account), "s3cret")
        XCTAssertNil(defaults.string(forKey: "password"), "The password must never sit in defaults")
        XCTAssertEqual(makeSettings().password, "s3cret")
    }

    func testReloadPasswordPicksUpALaterKeychainWrite() {
        // The read at init finds nothing, as when the Keychain is still locked.
        let settings = makeSettings()
        XCTAssertEqual(settings.password, "")

        Keychain.save(account: account, password: "arrived-later")
        settings.reloadPassword()

        XCTAssertEqual(settings.password, "arrived-later")
    }

    func testReloadPasswordKeepsTheValueWhenTheKeychainIsEmpty() {
        let settings = makeSettings()
        settings.password = "typed-by-the-user"
        Keychain.delete(account: account)

        settings.reloadPassword()

        XCTAssertEqual(settings.password, "typed-by-the-user",
                       "An empty read must not clear a good password")
    }

    /// macOS has no App Group. It must keep the standard defaults, or every
    /// user loses the settings they already have.
    func testMacOSUsesTheStandardDefaults() {
        XCTAssertEqual(SharedSettings.defaultStore, UserDefaults.standard)
    }
}
