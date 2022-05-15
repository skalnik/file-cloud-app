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
    var uploader = FileUploader.shared
    
    var body: some Scene {
        Settings {
            TabView {
                
            }.frame(width: 450, height: 250)
        }
    }
}
