import SwiftUI
import MenuBarExtraAccess
import AppKit
import Combine

struct MenuBarIcon: Scene {
    @State var isMenuPresented: Bool = false
    @EnvironmentObject private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("File Cloud", systemImage: $appDelegate.icon.wrappedValue) {
            MainMenu()
        }.menuBarExtraStyle(.menu)
        .menuBarExtraAccess(isPresented: $isMenuPresented)
    }
}

struct MainMenu: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        EmptyView().onAppear { }
        Text("📂☁️ File Cloud")
        Divider()
        Button("Settings") {
            openSettings()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.activate()
                if let settingsWindow = NSApplication.shared.windows
                    .first(where: { $0.title == "Settings" }) {
                    settingsWindow.level = .modalPanel
                    settingsWindow.makeKeyAndOrderFront(nil)
                    settingsWindow.level = .normal
                }
            }
        }
        .keyboardShortcut(",", modifiers: .command)
        Button("Quit") { NSApplication.shared.terminate(nil) }.keyboardShortcut("q", modifiers: .command)
    }
}
