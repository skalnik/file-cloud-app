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
    
    var allVars: [String] {[
        serverURL,
        username,
        password
    ]}
    
    var body: some View {
        Form {
            ControlGroup {
                TextField("Server URL", text: $serverURL, prompt: Text("https://cloud.example.com"))
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                TextField("Username", text: $username).autocorrectionDisabled(true)
                SecureField("Password", text: $password).autocorrectionDisabled(true)
            }.onChange(of: allVars) {
                uploader.reinit()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
