//
//  MenuBarExtra.swift
//  File Cloud (macOS)
//
//  Created by Mike Skalnik on 5/10/22.
//

import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UploadDelegate {
    var statusBarItem: NSStatusItem!
    var uploader: FileUploader!
    var notifications: Bool!
    var uploadOnEnter: Bool!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let serverURL = URL(string: UserDefaults.standard.string(forKey: "serverURL")!)
        
        self.uploader = FileUploader.init(serverURL: serverURL!, username: UserDefaults.standard.string(forKey: "username")!, password: UserDefaults.standard.string(forKey: "password")!)
        self.uploader.delegate = self
        
        self.uploadOnEnter = UserDefaults.standard.bool(forKey: "uploadOnEnter")
        
        let statusBar = NSStatusBar.system
        self.statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        
        initImage()
        statusBarItem.button?.registerForDraggedTypes([.fileURL])
        statusBarItem.button?.target = self
               
        statusBarItem.menu = createMenu()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, _) in
            self.notifications = granted
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateSettings), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    @objc func initImage() {
        statusBarItem.button?.image = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "File Cloud")
    }

    func delayedInit () {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: {timer in
            self.initImage()
        })
    }

    func createMenu() -> NSMenu {
        let menu = NSMenu()
        let title = NSMenuItem(title: "📂☁️ File Cloud", action: nil, keyEquivalent: "")
        title.isEnabled = false
        
        menu.addItem(title)
        menu.addItem(NSMenuItem.separator())
        
        let configureMenuItem = menu.addItem(withTitle: "Preferences…", action: #selector(configure), keyEquivalent: ",")
        configureMenuItem.target = self
        
        let quitMenuItem = menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitMenuItem.target = self
        
        return menu
    }
    
    func error(error: String) {
        DispatchQueue.main.sync {
            statusBarItem.button?.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Error!")
            delayedInit()
        }

        displayNotification(title: "File Cloud Error", body: error)
        print(error)
    }
    
    func uploaded(url: URL) {
        print("Uploaded")
        DispatchQueue.main.sync {
            statusBarItem.button?.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: "Uploaded!")
            delayedInit()
        }

        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(url.absoluteString, forType: NSPasteboard.PasteboardType.string)
        
        displayNotification(title: "File Uploaded!", body: "URL copied to your clipboard")
    }
    
    func uploading() {
        statusBarItem.button?.image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: "Uploading file")
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
    
    @objc func quit(_ sender: Any?) {
        NSApp.terminate(self)
    }
    
    @objc func configure(_ sender: Any?) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func dragEntered(_ sender: NSDraggingInfo) {
        // Check everytime on drag enter in case it's changed
        self.uploadOnEnter = UserDefaults.standard.bool(forKey: "uploadOnEnter")
        
        statusBarItem.button?.image? = NSImage(systemSymbolName: "cloud", accessibilityDescription: "Ready to upload")!
        
        if uploadOnEnter {
            if let fileURL = NSURL.init(from: sender.draggingPasteboard)?.standardized {
                uploader.fileURL = fileURL
                uploader.upload()
            }
        }
    }
    
    @objc func prepareDrag(_ sender: NSDraggingInfo) {
        if !uploadOnEnter {
            if let fileURL = NSURL.init(from: sender.draggingPasteboard)?.standardized {
                uploader.fileURL = fileURL
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
            initImage()
        }
    }
    
    @objc func updateSettings() {
        self.uploader.serverURL = URL(string: UserDefaults.standard.string(forKey: "serverURL")!)
        self.uploader.username = UserDefaults.standard.string(forKey: "username")
        self.uploader.password = UserDefaults.standard.string(forKey: "password")
        self.uploadOnEnter = UserDefaults.standard.bool(forKey: "uploadOnEnter")
    }
}
