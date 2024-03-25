import SwiftUI
import PhotosUI

struct UploadView: View {
    @ObservedObject var uploader: Uploader
    @State private var showingPhotoLibrary = false
    @State private var imageURL = URL(string: "http://example.com")!
    @State private var selectedImage: PhotosPickerItem? = nil
    
    var body: some View {
        ZStack {
            VStack {
                PhotosPicker(
                    selection: $selectedImage,
                    photoLibrary: .shared()
                    
                ) {
                    Image(systemName: "photo")
                    Text("Upload from Photos")
                }
                .modifier(BigButtonModifier())
                .onChange(of: selectedImage) {
                    Task {
                        if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                            selectedImage = nil
                            guard let image = UIImage(data: data) else { return }
                            guard let pngData = image.pngData() else { return }
                            uploader.setFile(data: pngData)
                        }
                    }
                }
                
                Button(action: {
                }) {
                    Image(systemName: "doc")
                    Text("Upload from Files")
                }.modifier(BigButtonModifier())
            }
            
            switch uploader.state {
            case .errored(let msg):
                Toast(image: "xmark", message: msg)
            case .idle:
                EmptyView()
            case .uploading:
                Toast(loading: true, message: "Uploading…")
            case .uploaded:
                Toast(image: "checkmark", message: "URL copied to clipboard!")
            }
        }
    }
}

#Preview {
    UploadView(uploader: Uploader())
}

struct BigButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 60)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
            .font(.title)
            .padding(.horizontal)
    }
}
