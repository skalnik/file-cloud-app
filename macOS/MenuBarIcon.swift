import SwiftUI
import MenuBarExtraAccess
import AppKit
import Combine

struct MenuBarIcon: Scene {
    @State var isMenuPresented: Bool = false
    @EnvironmentObject private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("File Cloud", systemImage: appDelegate.icon.systemName) {
            MainMenu()
        }.menuBarExtraStyle(.menu)
        .menuBarExtraAccess(isPresented: $isMenuPresented)
    }
}

struct MainMenu: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text("📂☁️ File Cloud")
        Divider()
        Button("Settings") {
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)
        Button("Quit") { NSApplication.shared.terminate(nil) }.keyboardShortcut("q", modifiers: .command)
    }
}
