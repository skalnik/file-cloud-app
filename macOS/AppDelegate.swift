import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UploadDelegate, ObservableObject {
    var statusBarItem: NSStatusItem!
    var uploader: FileUploader!
    var notifications: Bool!
    var uploadOnEnter: Bool!
    @Published var icon: String! = "cloud.fill"
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.uploader = FileUploader.init(serverURL: URL(string: UserDefaults.standard.string(forKey: "serverURL")!),
                                          username: UserDefaults.standard.string(forKey: "username"),
                                          password: UserDefaults.standard.string(forKey: "password"))
        self.uploader.delegate = self
        self.uploadOnEnter = UserDefaults.standard.bool(forKey: "uploadOnEnter")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, _) in
            self.notifications = granted
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateSettings), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    func setStatusBarItem(item: NSStatusItem!) {
        self.statusBarItem = item
        initStatusBar()
    }
    
    func initStatusBar() {
        statusBarItem.button?.registerForDraggedTypes([.fileURL])
        statusBarItem.button?.target = self
    }

    func defaultIcon() {
        self.icon = "cloud.fill"
    }
    
    func delayedInit () {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: {timer in
            self.defaultIcon()
        })
    }
    
    func error(error: String) {
        DispatchQueue.main.sync {
            self.icon = "xmark"
            delayedInit()
        }

        displayNotification(title: "File Cloud Error", body: error)
        print(error)
    }
    
    func uploaded(url: URL) {
        print("Uploaded")
        DispatchQueue.main.sync {
            self.icon = "checkmark"
            delayedInit()
        }

        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(url.absoluteString, forType: NSPasteboard.PasteboardType.string)
        
        displayNotification(title: "File Uploaded!", body: "URL copied to your clipboard")
    }
    
    func uploading() {
        self.icon = "arrow.up"
    }

    func displayNotification(title: String!, body: String!) {
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
    
    @objc func dragEntered(_ sender: NSDraggingInfo) {
        // Check everytime on drag enter in case it's changed
        self.uploadOnEnter = UserDefaults.standard.bool(forKey: "uploadOnEnter")
        
        self.icon = "cloud"
        
        if uploadOnEnter {
            if let fileURL = NSURL.init(from: sender.draggingPasteboard)?.standardized {
                uploader.setFromFileURL(fileURL: fileURL)
                uploader.upload()
            }
        }
    }
    
    @objc func prepareDrag(_ sender: NSDraggingInfo) {
        if !uploadOnEnter {
            if let fileURL = NSURL.init(from: sender.draggingPasteboard)?.standardized {
                uploader.setFromFileURL(fileURL: fileURL)
            }
        }
    }
    
    @objc func performDrag(_ sender: Any?) {
        if !uploadOnEnter {
            uploader.upload()
        }
    }
    
    @objc func dragExit(_ sender: Any? ) {
        if !uploadOnEnter {
            defaultIcon()
        }
    }
    
    @objc func updateSettings() {
        self.uploader.serverURL = URL(string: UserDefaults.standard.string(forKey: "serverURL")!)
        self.uploader.username = UserDefaults.standard.string(forKey: "username")
        self.uploader.password = UserDefaults.standard.string(forKey: "password")
        self.uploadOnEnter = UserDefaults.standard.bool(forKey: "uploadOnEnter")
    }
}
