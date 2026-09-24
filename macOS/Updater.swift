import SwiftUI
import Sparkle

final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
    }
}

struct CheckForUpdatesButton: View {
    @ObservedObject private var model: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.model = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates…", action: updater.checkForUpdates)
            .disabled(!model.canCheckForUpdates)
    }
}

struct AutomaticUpdatesToggle: View {
    private let updater: SPUUpdater
    @State private var isOn: Bool

    init(updater: SPUUpdater) {
        self.updater = updater
        self._isOn = State(initialValue: updater.automaticallyChecksForUpdates)
    }

    var body: some View {
        Toggle("Automatically check for updates", isOn: $isOn)
            .onChange(of: isOn) { _, newValue in
                updater.automaticallyChecksForUpdates = newValue
            }
    }
}
