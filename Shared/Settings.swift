import Foundation
import Combine

class SharedSettings: ObservableObject {
    static let suiteName = "group.skalnik.file-cloud"

    static var defaultStore: UserDefaults {
#if os(macOS)
        .standard
#else
        UserDefaults(suiteName: suiteName) ?? .standard
#endif
    }

    private let defaults: UserDefaults
    private let keychainAccount: String

    @Published var serverURL: String {
        didSet { defaults.set(serverURL, forKey: "serverURL") }
    }

    @Published var username: String {
        didSet { defaults.set(username, forKey: "username") }
    }

    @Published var password: String {
        didSet { Keychain.save(account: keychainAccount, password: password) }
    }

    /// macOS only. The upload starts when the drag enters the menu bar icon,
    /// not when it drops. This works around a macOS bug with Dock Stacks.
    @Published var uploadOnEnter: Bool {
        didSet { defaults.set(uploadOnEnter, forKey: "uploadOnEnter") }
    }

    init(defaults: UserDefaults = SharedSettings.defaultStore,
         keychainAccount: String = "password") {
        self.defaults = defaults
        self.keychainAccount = keychainAccount
        self.serverURL = defaults.string(forKey: "serverURL") ?? ""
        self.username = defaults.string(forKey: "username") ?? ""
        self.password = Keychain.read(account: keychainAccount) ?? ""
        self.uploadOnEnter = defaults.bool(forKey: "uploadOnEnter")
    }

    func reloadPassword() {
        guard let stored = Keychain.read(account: keychainAccount), stored != password else {
            return
        }

        password = stored
    }

#if DEBUG
    static var preview: SharedSettings {
        SharedSettings(defaults: UserDefaults(suiteName: "preview.file-cloud") ?? .standard,
                       keychainAccount: "preview-password")
    }
#endif
}
