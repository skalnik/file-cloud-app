//
//  MainView.swift
//  File Cloud
//
//  Created by Mike Skalnik on 5/27/22.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var settings: SharedSettings

    var body: some View {
        TabView {
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "arrow.up.circle")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(SharedSettings())
}
