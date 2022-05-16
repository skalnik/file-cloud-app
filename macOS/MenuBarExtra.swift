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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.uploader = FileUploader.shared
        self.uploader.serverURL = URL(string: UserDefaults.standard.string(forKey: "serverURL")!)!
        self.uploader.username = UserDefaults.standard.string(forKey: "username")
        self.uploader.password = UserDefaults.standard.string(forKey: "password")
        self.uploader.delegate = self
        
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        initImage()
        statusBarItem.button?.registerForDraggedTypes([.fileURL])
        statusBarItem.button?.target = self
               
        self.statusBarItem.menu = createMenu()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, _) in
            self.notifications = granted
        }
    }
    
    func initImage() {
        statusBarItem.button?.image = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "File Cloud")
    }

    func delayedInit () {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: {timer in
            self.initImage()
        })
    }

    func createMenu() -> NSMenu {
        let menu = NSMenu()
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
        DispatchQueue.main.sync {
            statusBarItem.button?.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: "Uploaded!")

            delayedInit()
        }
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(url.absoluteString, forType: NSPasteboard.PasteboardType.string)
        
        displayNotification(title: "File Uploaded!", body: "URL copied to your clipboard")
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
        exit(0)
    }
    
    @objc func configure(_ sender: Any?) {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

extension NSStatusBarButton {
    open override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        image = NSImage(systemSymbolName: "cloud", accessibilityDescription: "Ready to upload")
        return .copy
    }

    open override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let fileURL = NSURL.init(from: sender.draggingPasteboard)?.standardized {
            FileUploader.shared.fileURL = fileURL
            return true
        } else {
            return false
        }
    }

    open override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: "Uploading file")
        FileUploader.shared.upload()

        return true
    }
    
    open override func draggingExited(_ sender: NSDraggingInfo?) {
        image = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "File Cloud")
    }
}