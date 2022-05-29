//
//  MainView.swift
//  File Cloud
//
//  Created by Mike Skalnik on 5/27/22.
//

import SwiftUI

struct MainView: View {
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
