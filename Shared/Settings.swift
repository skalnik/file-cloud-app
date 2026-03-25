import Foundation
import Combine

class SharedSettings: ObservableObject {
    #if os(iOS)
    static let suiteName = "group.skalnik.file-cloud"
    #endif

    private let defaults: UserDefaults

    @Published var serverURL: String {
        didSet { defaults.set(serverURL, forKey: "serverURL") }
    }

    @Published var username: String {
        didSet { defaults.set(username, forKey: "username") }
    }

    @Published var password: String {
        didSet {
            Keychain.save(account: "password", password: password)
            #if os(macOS)
            NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
            #endif
        }
    }

    #if os(macOS)
    @Published var uploadOnEnter: Bool {
        didSet { defaults.set(uploadOnEnter, forKey: "uploadOnEnter") }
    }
    #endif

    init() {
        #if os(iOS)
        let defaults = UserDefaults(suiteName: SharedSettings.suiteName) ?? .standard
        #else
        let defaults = UserDefaults.standard
        #endif
        self.defaults = defaults
        self.serverURL = defaults.string(forKey: "serverURL") ?? ""
        self.username = defaults.string(forKey: "username") ?? ""
        self.password = Keychain.read(account: "password") ?? ""
        #if os(macOS)
        self.uploadOnEnter = defaults.bool(forKey: "uploadOnEnter")
        #endif
    }
}
