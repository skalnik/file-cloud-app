import SwiftUI
import PhotosUI

struct UploadView: View {
    @EnvironmentObject private var uploader: Uploader
    @State private var showingPhotoLibrary = false
    @State private var imageURL = URL(string: "http://example.com")!
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var image: UIImage? = nil
    @State private var name: String? = nil
    
    var body: some View {
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
                        if let image = UIImage(data: data) {
                            if let pngData = image.pngData() {
                                print(pngData)
                                let name = String(Date.timeIntervalSinceReferenceDate).replacingOccurrences(of: ".", with: "-") + ".png"
                                uploader.uploader.data = pngData
                                uploader.uploader.fileName = String(describing: name)
                                uploader.uploader.mimeType = "image/png"
                                uploader.uploader.upload()
                            }
                        }
                    }
                }
            }
            
            Button(action: {
            }) {
                Image(systemName: "doc")
                Text("Upload from Files")
            }.modifier(BigButtonModifier())
        }
    }
}

struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
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
