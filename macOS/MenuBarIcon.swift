import SwiftUI
import MenuBarExtraAccess

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
        SettingsLink().keyboardShortcut(",", modifiers: .command)
        Button("Quit") { NSApplication.shared.terminate(nil) }.keyboardShortcut("q", modifiers: .command)
    }
}

#Preview {
    MainMenu()
}
