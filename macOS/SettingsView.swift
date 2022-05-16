//
//  SettingsView.swift
//  File Cloud (macOS)
//
//  Created by Mike Skalnik on 5/16/22.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("serverURL") var serverURL: String = ""
    @AppStorage("username") var username: String = ""
    @AppStorage("password") var password: String = ""
    
    var body: some View {
        VStack {
            Form {
                TextField("Server URL", text: $serverURL, prompt: Text("https://cloud.example.com"))
                TextField("Username", text: $username).disableAutocorrection(true)
                SecureField("Password", text: $password)
            }
            Button("Check") {
                return
            }
        }
        .padding()
        .frame(width: 400, height: 150)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
        }
    }
}
