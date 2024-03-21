import Foundation
class Uploader: UploadDelegate, ObservableObject {
    let uploader = FileUploader.init(
        serverURL: URL(string: (UserDefaults.standard.string(forKey: "serverURL") ?? "https://cloud.example.com")),
        username: UserDefaults.standard.string(forKey: "username"),
        password: UserDefaults.standard.string(forKey: "password"))
    
    func error(error: String) {
        
    }
    
    func uploaded(url: URL) {
        
    }
    
    func uploading() {
        
    }
    
    func valid() {
        
    }
    
    func reinit() {
        self.uploader.serverURL = URL(string: (UserDefaults.standard.string(forKey: "serverURL") ?? "https://cloud.example.com"))
        self.uploader.username = UserDefaults.standard.string(forKey: "username")
        self.uploader.password = UserDefaults.standard.string(forKey: "password")
    }
}
