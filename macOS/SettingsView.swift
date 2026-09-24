import SwiftUI
import LaunchAtLogin
import Sparkle

struct SettingsView: View {
    @EnvironmentObject var settings: SharedSettings
    var updater: SPUUpdater?
    @State var pane = 1

    var body: some View {
        TabView(selection: $pane) {
            VStack {
                Form {
                    TextField("Server URL", text: $settings.serverURL, prompt: Text("https://cloud.example.com"))
                    TextField("Username", text: $settings.username)
                    SecureField("Password", text: $settings.password)
                }
            }
            .tabItem {
                Label("Authentication", systemImage: "lock")
            }
            .padding()
            .tag(1)
            
            VStack(alignment: .leading) {
                LaunchAtLogin.Toggle()
                if let updater {
                    AutomaticUpdatesToggle(updater: updater)
                }
                Toggle(isOn: $settings.uploadOnEnter) {
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
        .frame(width:420)
        .onAppear { settings.reloadPassword() }
    }
}

#Preview("Authentication") {
    SettingsView(pane: 1).environmentObject(SharedSettings.preview)
}

#Preview("Advanced") {
    SettingsView(pane: 2).environmentObject(SharedSettings.preview)
}
