import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    let onPick: (Result<URL, Error>) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (Result<URL, Error>) -> Void

        init(onPick: @escaping (Result<URL, Error>) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            // No result means the user cancelled. That is not an error.
            guard let provider = results.first?.itemProvider else { return }

            let imageType = UTType.image.identifier
            guard provider.hasItemConformingToTypeIdentifier(imageType) else {
                onPick(.failure(PickerError.noImage))
                return
            }

            provider.loadFileRepresentation(forTypeIdentifier: imageType) { url, error in
                let result: Result<URL, Error>
                if let url = url {
                    result = Result { try TemporaryFile.copy(from: url) }
                } else {
                    result = .failure(error ?? PickerError.noImage)
                }

                DispatchQueue.main.async {
                    self.onPick(result)
                }
            }
        }
    }
}
