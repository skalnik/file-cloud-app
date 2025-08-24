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
        .menuBarExtraAccess(isPresented: $isMenuPresented) { statusItem in
            AppDelegate().setStatusBarItem(item: statusItem)
       }
    }
}

struct MainMenu: View {
    var body: some View {
        Text("📂☁️ File Cloud")
        Divider()
        SettingsLink()
            .keyboardShortcut(",", modifiers: .command)
            .modifier(SettingsWindowActivator())
        Button("Quit") { NSApplication.shared.terminate(nil) }.keyboardShortcut("q", modifiers: .command)
    }
}

struct SettingsWindowActivator: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApplication.shared.windows {
                    if window.title == "Settings" {
                        window.makeKeyAndOrderFront(nil)
                        return
                    }
                }
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
    }
}
