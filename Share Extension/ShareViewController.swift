import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusImageView = UIImageView()
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        spinner.translatesAutoresizingMaskIntoConstraints = false
        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        statusImageView.contentMode = .scaleAspectFit
        statusImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48)
        statusImageView.isHidden = true

        statusLabel.textAlignment = .center
        statusLabel.font = .preferredFont(forTextStyle: .title3)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = true

        view.addSubview(spinner)
        view.addSubview(statusImageView)
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            statusLabel.topAnchor.constraint(equalTo: statusImageView.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])

        spinner.startAnimating()
        handleSharedItem()
    }

    private func handleSharedItem() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else {
            finish(error: "No item to share")
            return
        }

        let imageType = UTType.image.identifier
        let fileType = UTType.item.identifier

        let typeToLoad = provider.hasItemConformingToTypeIdentifier(imageType) ? imageType : fileType

        provider.loadFileRepresentation(forTypeIdentifier: typeToLoad) { [weak self] url, error in
            guard let self = self, let url = url else {
                DispatchQueue.main.async {
                    self?.finish(error: error?.localizedDescription ?? "Could not load file")
                }
                return
            }

            let tempDir = FileManager.default.temporaryDirectory
            let dest = tempDir.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)

            do {
                try FileManager.default.copyItem(at: url, to: dest)
            } catch {
                DispatchQueue.main.async {
                    self.finish(error: "Could not copy file")
                }
                return
            }

            self.upload(fileURL: dest)
        }
    }

    private func upload(fileURL: URL) {
        let settings = SharedSettings()

        guard !settings.serverURL.isEmpty else {
            DispatchQueue.main.async {
                self.finish(error: "Server URL not configured. Open File Cloud to set up.")
            }
            return
        }

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
                    self.finish(uploadedURL: url)
                }
            } catch {
                await MainActor.run {
                    self.finish(error: error.localizedDescription)
                }
            }
        }
    }

    private func finish(uploadedURL: URL? = nil, error: String? = nil) {
        spinner.stopAnimating()
        spinner.isHidden = true
        statusImageView.isHidden = false

        if let url = uploadedURL {
            statusImageView.image = UIImage(systemName: "checkmark.circle.fill")
            statusImageView.tintColor = .systemGreen
            statusLabel.text = "URL copied to clipboard\n\(url.absoluteString)"
            statusLabel.isHidden = false
        } else if let error = error {
            statusImageView.image = UIImage(systemName: "xmark.circle.fill")
            statusImageView.tintColor = .systemRed
            statusLabel.text = error
            statusLabel.isHidden = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
