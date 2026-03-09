import SwiftUI

struct UploadView: View {
    @EnvironmentObject var settings: SharedSettings
    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var uploadState: UploadState = .idle

    enum UploadState: Equatable {
        case idle
        case uploading
        case success(URL)
        case error(String)
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 24) {
                Spacer()

                statusView

                VStack(spacing: 16) {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Upload Photo", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        showDocumentPicker = true
                    } label: {
                        Label("Upload File", systemImage: "doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.horizontal)
                .padding(.bottom, geo.size.height * 0.3)
            }
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker { url in
                upload(fileURL: url)
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker { url in
                upload(fileURL: url)
            }
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch uploadState {
        case .idle:
            EmptyView()
        case .uploading:
            ProgressView("Uploading...")
        case .success(let url):
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 48))
                Text("Uploaded!")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(url.absoluteString)
                    .font(.body.monospaced())
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Button("Copy URL") {
                    UIPasteboard.general.url = url
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        case .error(let message):
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.largeTitle)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    init(uploadState: UploadState = .idle) {
        _uploadState = State(initialValue: uploadState)
    }

    private func upload(fileURL: URL) {
        uploadState = .uploading

        let uploader = FileUploader(
            serverURL: URL(string: settings.serverURL),
            username: settings.username,
            password: settings.password
        )
        uploader.fileURL = fileURL

        Task {
            do {
                let url = try await uploader.uploadAsync()
                await MainActor.run {
                    UIPasteboard.general.url = url
                    uploadState = .success(url)
                }
            } catch {
                await MainActor.run {
                    uploadState = .error(error.localizedDescription)
                }
            }
        }
    }
}

#Preview("Idle") {
    UploadView()
        .environmentObject(SharedSettings())
}

#Preview("Uploading") {
    UploadView(uploadState: .uploading)
        .environmentObject(SharedSettings())
}

#Preview("Success") {
    UploadView(uploadState: .success(URL(string: "https://cloud.example.com/acab13exrtalong.png")!))
        .environmentObject(SharedSettings())
}

#Preview("Error") {
    UploadView(uploadState: .error("Connection refused"))
        .environmentObject(SharedSettings())
}
