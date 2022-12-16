//
//  SettingsView.swift
//  File Cloud
//
//  Created by Mike Skalnik on 6/11/22.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("serverURL") var serverURL: String = ""
    @AppStorage("username") var username: String = ""
    @AppStorage("password") var password: String = ""
    
    var body: some View {
        Form {
            TextField("Server URL", text: $serverURL, prompt: Text("https://cloud.example.com"))
            TextField("Username", text: $username)
            SecureField("Password", text: $password)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
