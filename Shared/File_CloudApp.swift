//
//  File_CloudApp.swift
//  Shared
//
//  Created by Mike Skalnik on 5/10/22.
//

import SwiftUI

@main
struct File_CloudApp: App {
    #if macOS
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var body: some Scene {
        #if macOS
        Settings {
            SettingsView()
        }
        #else
        WindowGroup {
            VStack {
               Text("Hello World")
            }
        }
        #endif
        
    }
}
