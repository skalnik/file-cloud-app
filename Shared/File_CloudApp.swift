//
//  File_CloudApp.swift
//  Shared
//
//  Created by Mike Skalnik on 5/10/22.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct File_CloudApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    struct MyDropDelegate: DropDelegate {
        func dropEntered(info: DropInfo) {
            return
        }
        func dropExited(info: DropInfo) {
        }
        func dropUpdated(info: DropInfo) -> DropProposal? {
            return nil
        }
        func performDrop(info: DropInfo) -> Bool {
            return true
        }
    }
    
    
    var body: some Scene {
#if os(macOS)
        Settings {
            SettingsView()
        }
        
        @State var colorIndex = 0
        @State var isInserted = true
        let dropDelegate = MyDropDelegate()
        
        MenuBarExtra(content: {
            Text("📁☁️ File Cloud")
            Divider()
            Button("Preferences…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }.keyboardShortcut(",")
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }, label: {
            Text("Butt").onDrop(of: [.fileURL], delegate: dropDelegate)
        })
#endif
#if os(iOS)
        WindowGroup {
            MainView()
        }
#endif
    }
}
