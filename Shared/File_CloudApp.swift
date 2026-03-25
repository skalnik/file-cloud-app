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
    @StateObject private var settings = SharedSettings()

    var body: some Scene {
#if os(macOS)
        MenuBarIcon().environmentObject(appDelegate)
        Settings {
            SettingsView()
                .environmentObject(settings)
        }
#endif
#if os(iOS)
        WindowGroup {
            MainView()
                .environmentObject(settings)
        }
#endif
    }
}
