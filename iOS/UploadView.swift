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
        VStack(spacing: 28) {
            Text("File Cloud")
                .font(.system(size: 100, weight: .bold))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .padding(.horizontal)

            Spacer()

            statusView

            Spacer()

            VStack(spacing: 16) {
                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Upload Photo", systemImage: "photo")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)

                Button {
                    showDocumentPicker = true
                } label: {
                    Label("Upload File", systemImage: "doc")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
            }
            .disabled(settings.serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding(.top, 48)
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(onPick: picked)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(onPick: picked)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch uploadState {
        case .idle:
            EmptyView()
        case .uploading:
            ProgressView("Uploading...")
                .font(.title)
        case .success(let url):
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 52))
                Text("Uploaded!")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(url.absoluteString)
                    .font(.title3.monospaced())
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Button{
                    UIPasteboard.general.url = url
                } label: {
                    Label("Copy URL", systemImage: "link")
                        .font(.title2)
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

    private func picked(_ result: Result<URL, Error>) {
        switch result {
        case .success(let fileURL): upload(fileURL: fileURL)
        case .failure(let error): uploadState = .error(error.localizedDescription)
        }
    }

    private func upload(fileURL: URL) {
        uploadState = .uploading

        let uploader = FileUploader(
            serverURL: URL(string: settings.serverURL),
            username: settings.username,
            password: settings.password
        )

        Task {
            defer { TemporaryFile.remove(fileURL) }

            do {
                let url = try await uploader.uploadAsync(fileURL: fileURL)
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
        .environmentObject(SharedSettings.preview)
}

#Preview("Uploading") {
    UploadView(uploadState: .uploading)
        .environmentObject(SharedSettings.preview)
}

#Preview("Success") {
    UploadView(uploadState: .success(URL(string: "https://cloud.example.com/acab13exrtalong.png")!))
        .environmentObject(SharedSettings.preview)
}

#Preview("Error") {
    UploadView(uploadState: .error("Connection refused"))
        .environmentObject(SharedSettings.preview)
}
