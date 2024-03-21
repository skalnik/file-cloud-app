import Foundation
class Uploader: UploadDelegate, ObservableObject {
    let uploader = FileUploader.init(
        serverURL: URL(string: (UserDefaults.standard.string(forKey: "serverURL") ?? "")),
        username: UserDefaults.standard.string(forKey: "username"),
        password: UserDefaults.standard.string(forKey: "password"))
    
    init() {
        self.uploader.delegate = self
    }
    
    func error(error: String) {
        print(error)
    }
    
    func uploaded(url: URL) {
        print(url)
    }
    
    func uploading() {
        print("Uploading…")
    }
    
    func valid() {
        print("Auth valid")
    }
    
    func reinit() {
        self.uploader.serverURL = URL(string: (UserDefaults.standard.string(forKey: "serverURL") ?? ""))
        self.uploader.username = UserDefaults.standard.string(forKey: "username")
        self.uploader.password = UserDefaults.standard.string(forKey: "password")
    }
}
