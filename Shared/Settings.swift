import Foundation
import Combine

class SharedSettings: ObservableObject {
    static let suiteName = "group.skalnik.file-cloud"

    private let defaults: UserDefaults

    @Published var serverURL: String {
        didSet { defaults.set(serverURL, forKey: "serverURL") }
    }

    @Published var username: String {
        didSet { defaults.set(username, forKey: "username") }
    }

    @Published var password: String {
        didSet { Keychain.save(account: "password", password: password) }
    }

    init() {
        let defaults = UserDefaults(suiteName: SharedSettings.suiteName) ?? .standard
        self.defaults = defaults
        self.serverURL = defaults.string(forKey: "serverURL") ?? ""
        self.username = defaults.string(forKey: "username") ?? ""
        self.password = Keychain.read(account: "password") ?? ""
    }
}
