import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SharedSettings
    @State private var connectionStatus: ConnectionStatus = .idle

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
        NavigationView {
            Form {
                Section {
                    TextField("Server URL", text: $settings.serverURL, prompt: Text("https://cloud.example.com"))
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Server URL")
                } footer: {
                    if settings.serverURL.isEmpty {
                        Text("Enter your File Cloud server URL")
                    }
                }

                Section(header: Text("Authentication")) {
                    TextField("Username", text: $settings.username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $settings.password)
                        .textContentType(.password)
                }

                Section {
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
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity)
                } footer: {
                    Text("Once connected, you can also use the share sheet from any app to upload files!")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Settings")
            .onChange(of: settings.serverURL) { connectionStatus = .idle }
            .onChange(of: settings.username) { connectionStatus = .idle }
            .onChange(of: settings.password) { connectionStatus = .idle }
        }
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

#Preview {
    SettingsView()
        .environmentObject(SharedSettings())
}
