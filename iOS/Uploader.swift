import Foundation
import UIKit

enum UploaderState {
    case idle
    case errored(error: String)
    case uploading
    case uploaded
}

class Uploader: UploadDelegate, ObservableObject {
    @Published var error: String?
    @Published var state = UploaderState.idle
    
    let uploader = FileUploader.init(
        serverURL: URL(string: (UserDefaults.standard.string(forKey: "serverURL") ?? "")),
        username: UserDefaults.standard.string(forKey: "username"),
        password: UserDefaults.standard.string(forKey: "password"))
    
    init() {
        uploader.delegate = self
    }
    
    func error(error: String) {
        DispatchQueue.main.async {
            self.state = .errored(error: error)
        }
        delayedIdle()
    }
    
    func uploaded(url: URL) {
        DispatchQueue.main.async {
            self.state = .uploaded
            UIPasteboard.general.string = String(describing: url)
        }
        delayedIdle()
    }
    
    func uploading() {
        DispatchQueue.main.async {
            self.state = .uploading
        }
    }
    
    func valid() {
        print("Auth valid")
    }
    
    func delayedIdle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            self.state = .idle
         })
    }
    
    func setFile(data: Data) {
        let name = String(Date.timeIntervalSinceReferenceDate).replacingOccurrences(of: ".", with: "-") + ".png"
        
        uploader.mimeType = "image/png"
        uploader.fileName = String(describing: name)
        uploader.data = data
        
        uploader.upload()
    }
    
    func reinit() {
        self.uploader.serverURL = URL(string: (UserDefaults.standard.string(forKey: "serverURL") ?? ""))
        self.uploader.username = UserDefaults.standard.string(forKey: "username")
        self.uploader.password = UserDefaults.standard.string(forKey: "password")
    }
}
