//
//  File_CloudApp.swift
//  Shared
//
//  Created by Mike Skalnik on 5/10/22.
//

import SwiftUI

@main
struct File_CloudApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
