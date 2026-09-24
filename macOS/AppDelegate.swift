import AppKit
import Sparkle
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UploadDelegate, ObservableObject {
    let settings: SharedSettings
    let updaterController = SPUStandardUpdaterController(startingUpdater: true,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)
    var notifications: Bool = false
    @Published var icon: UploadIcon = .idle

    /// The file waits here between the start of the drag and the drop.
    private var pendingFileURL: URL?

    override init() {
        // Move an old plaintext password into the Keychain before the settings
        // read it.
        if let oldPassword = UserDefaults.standard.string(forKey: "password"), !oldPassword.isEmpty {
            Keychain.save(account: "password", password: oldPassword)
            UserDefaults.standard.removeObject(forKey: "password")
        }

        self.settings = SharedSettings()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, _) in
            self.notifications = granted
        }
    }

    private var resetTimer: Timer?

    /// The only way the icon changes. AppKit needs the main thread, and the
    /// delegate calls arrive on the queue of URLSession.
    private func show(_ icon: UploadIcon) {
        DispatchQueue.main.async {
            self.resetTimer?.invalidate()
            self.icon = icon

            guard icon.isTemporary else { return }

            self.resetTimer = Timer.scheduledTimer(withTimeInterval: UploadIcon.temporaryDuration,
                                                   repeats: false) { _ in
                self.show(.idle)
            }
        }
    }
    
    func error(error: String) {
        show(.failure)

        displayNotification(title: "File Cloud Error", body: error)
        print(error)
    }
    
    func uploaded(url: URL) {
        print("Uploaded")
        show(.success)

        // This runs on the queue of URLSession. AppKit needs the main thread.
        DispatchQueue.main.async {
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(url.absoluteString, forType: NSPasteboard.PasteboardType.string)
        }

        displayNotification(title: "File Uploaded!", body: "URL copied to your clipboard")
    }
    
    func uploading() {
        show(.uploading)
    }

    func displayNotification(title: String, body: String) {
        if !notifications {
            return
        }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }

    /// Makes an uploader from the settings of this moment. The upload task
    /// keeps it alive until the server answers.
    private func upload(fileURL: URL) {
        // The read at launch can fail, so ask the Keychain again.
        settings.reloadPassword()

        let uploader = FileUploader(serverURL: URL(string: settings.serverURL),
                                    username: settings.username,
                                    password: settings.password)
        uploader.delegate = self
        uploader.upload(fileURL: fileURL)
    }

    @objc func dragEntered(_ sender: NSDraggingInfo) {
        show(.dragging)

        guard settings.uploadOnEnter,
              let fileURL = NSURL.init(from: sender.draggingPasteboard)?.standardized else {
            return
        }

        upload(fileURL: fileURL)
    }
    
    @objc func prepareDrag(_ sender: NSDraggingInfo) {
        if !settings.uploadOnEnter {
            pendingFileURL = NSURL.init(from: sender.draggingPasteboard)?.standardized
        }
    }

    @objc func performDrag(_ sender: Any?) {
        guard !settings.uploadOnEnter, let fileURL = pendingFileURL else { return }

        pendingFileURL = nil
        upload(fileURL: fileURL)
    }
    
    @objc func dragExit(_ sender: Any? ) {
        if !settings.uploadOnEnter {
            show(.idle)
        }
    }
}
