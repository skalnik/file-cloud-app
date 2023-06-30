//
//  SettingsView.swift
//  File Cloud (macOS)
//
//  Created by Mike Skalnik on 5/16/22.
//

import SwiftUI
import LaunchAtLogin

struct SettingsView: View {
    @AppStorage("serverURL") var serverURL: String = ""
    @AppStorage("username") var username: String = ""
    @AppStorage("password") var password: String = ""
    @AppStorage("uploadOnEnter") var uploadOnEnter: Bool = false
    @State var pane = 1
    
    var body: some View {
        TabView(selection: $pane) {
            VStack {
                Form {
                    TextField("Server URL", text: $serverURL, prompt: Text("https://cloud.example.com"))
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                }
            }
            .tabItem {
                Label("Authentication", systemImage: "lock")
            }
            .padding()
            .frame(width: 420)
            .tag(1)
            
            VStack(alignment: .leading) {
                LaunchAtLogin.Toggle()
                Toggle(isOn: $uploadOnEnter) {
                    HStack {
                        Text("Begin uploading upon drag enter")
                        Image(systemName: "info.circle.fill")
                            .help("Allows faster uploading, along with uploading from Dock Stacks, due to macOS Bug")
                    }
                }
            }
            .tabItem {
                Label("Advanced", systemImage: "gear")
            }
            .padding()
            .tag(2)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView(pane: 1)
            SettingsView(pane: 2)
        }
    }
}
