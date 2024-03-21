//
//  MainView.swift
//  File Cloud
//
//  Created by Mike Skalnik on 5/27/22.
//

import SwiftUI

struct MainView: View {
    @State private var selection: Tab = .upload
    @EnvironmentObject private var uploader: Uploader
    
    enum Tab {
        case upload
        case settings
    }
    
    init() {
        UITabBar.appearance().isTranslucent = false
    }
    
    var body: some View {
        TabView(selection: $selection) {
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "arrow.up.doc")
                }
                .tag(Tab.upload)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }.background(Color.white)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
