//
//  MenuBarExtra.swift
//  File Cloud (macOS)
//
//  Created by Mike Skalnik on 5/10/22.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, UploadDelegate {
    var statusBarItem: NSStatusItem!
    var uploader: FileUploader!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.uploader = FileUploader.shared
        self.uploader.serverURL = URL(string: "http://localhost:8080")!
        self.uploader.delegate = self
        
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.image = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "File Cloud")
        statusBarItem.button?.registerForDraggedTypes([.fileURL])
        statusBarItem.button?.target = self
               
        self.statusBarItem.menu = createMenu()
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        let configureMenuItem = menu.addItem(withTitle: "Configure", action: #selector(configure), keyEquivalent: ",")
        configureMenuItem.target = self
        
        let quitMenuItem = menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitMenuItem.target = self
        
        return menu
    }
    
    func error(error: String) {
        DispatchQueue.main.sync {
            statusBarItem.button?.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Error!")
        }
        
        print(error)
    }
    
    func uploaded(url: URL) {
        DispatchQueue.main.sync {
            statusBarItem.button?.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: "Uploaded!")
        }
        print("Uploaded")
        
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(url.absoluteString, forType: NSPasteboard.PasteboardType.string)
    }
    
    @objc func quit(_ sender: Any?) {
        exit(0)
    }
    
    @objc func configure(_ sender: Any?) {
    }
}

extension NSStatusBarButton {
    open override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        true
    }

    open override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("dragging entered")
        image = NSImage(systemSymbolName: "cloud", accessibilityDescription: "Ready to upload")
        return .copy
    }

    open override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let fileURL = (NSURL.init(from: sender.draggingPasteboard)?.standardized!)!
        FileUploader.shared.fileURL = fileURL
        return true
    }
    
    open override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        FileUploader.shared.upload()
    }
    
    open override func draggingExited(_ sender: NSDraggingInfo?) {
        image = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "File Cloud")
        print("Draging exit")
    }
}
