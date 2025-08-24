//
//  File_CloudApp.swift
//  Shared
//
//  Created by Mike Skalnik on 5/10/22.
//

import SwiftUI

@main
struct File_CloudApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    
    
    var body: some Scene {
#if os(macOS)
        MenuBarIcon().environmentObject(appDelegate)
        Settings {
            SettingsView()
        }
#endif
#if os(iOS)
        WindowGroup {
            MainView()
        }
#endif
    }
}
