import SwiftUI
import LaunchAtLogin

struct SettingsView: View {
    @EnvironmentObject var settings: SharedSettings
    @State private var connectionStatus: ConnectionStatus = .idle
    @State var pane = 1

    enum ConnectionStatus: Equatable {
        case idle
        case testing
        case success
        case error(String)
    }

    private var connectionTint: Color {
        switch connectionStatus {
        case .success: .green
        case .error: .red
        default: .blue
        }
    }

    private var hasCredentials: Bool {
        !settings.serverURL.isEmpty && !settings.username.isEmpty && !settings.password.isEmpty
    }

    var body: some View {
        TabView(selection: $pane) {
            VStack {
                Form {
                    TextField("Server URL", text: $settings.serverURL, prompt: Text("https://cloud.example.com"))
                    TextField("Username", text: $settings.username)
                    SecureField("Password", text: $settings.password)
                }

                Button(action: testConnection) {
                    HStack {
                        switch connectionStatus {
                        case .idle:
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("Test Connection")
                        case .testing:
                            ProgressView()
                                .controlSize(.small)
                            Text("Testing...")
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                            Text("Lookin good boss!")
                        case .error(let message):
                            Image(systemName: "xmark.circle.fill")
                            Text(message)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(connectionTint)
                .disabled(!hasCredentials || connectionStatus == .testing)
            }
            .tabItem {
                Label("Authentication", systemImage: "lock")
            }
            .padding()
            .tag(1)

            VStack(alignment: .leading) {
                LaunchAtLogin.Toggle()
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
        .onChange(of: settings.serverURL) { connectionStatus = .idle }
        .onChange(of: settings.username) { connectionStatus = .idle }
        .onChange(of: settings.password) { connectionStatus = .idle }
    }

    private func testConnection() {
        guard let url = URL(string: settings.serverURL), !settings.serverURL.isEmpty else {
            connectionStatus = .error("Invalid server URL")
            return
        }

        connectionStatus = .testing

        var request = URLRequest(url: url)
        if !settings.username.isEmpty {
            let loginString = "\(settings.username):\(settings.password)"
            let loginData = Data(loginString.utf8)
            request.setValue("Basic \(loginData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    connectionStatus = .error(error.localizedDescription)
                } else if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    connectionStatus = .success
                } else if let http = response as? HTTPURLResponse {
                    connectionStatus = .error("HTTP \(http.statusCode)")
                } else {
                    connectionStatus = .error("Unknown error")
                }
            }
        }.resume()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView(pane: 1)
                .environmentObject(SharedSettings())
            SettingsView(pane: 2)
                .environmentObject(SharedSettings())
        }
    }
}
