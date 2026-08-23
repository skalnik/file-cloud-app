import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (Result<URL, Error>) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (Result<URL, Error>) -> Void

        init(onPick: @escaping (Result<URL, Error>) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                onPick(.failure(PickerError.noAccess))
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            onPick(Result { try TemporaryFile.copy(from: url) })
        }
    }
}

enum PickerError: LocalizedError {
    case noAccess
    case noImage

    var errorDescription: String? {
        switch self {
        case .noAccess: "Could not read the file you picked"
        case .noImage: "Could not read the photo you picked"
        }
    }
}
