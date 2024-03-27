//
//  FileUploader.swift
//  File Cloud
//
//  Created by Mike Skalnik on 5/12/22.
//

import Foundation
import UniformTypeIdentifiers

protocol UploadDelegate {
    func error(error: String)
    func uploaded(url: URL)
    func uploading()
}

class FileUploader: NSObject {
    var serverURL: URL?
    var username: String?
    var password: String?
    
    let urlSession: URLSession
    
    var mimeType: String?
    var fileName: String?
    var data: Data?
    
    var delegate: UploadDelegate?
    
    struct FileCloudResponse: Codable {
        var url: String
    }
    
    init(serverURL: URL?, username: String?, password: String?) {
        self.serverURL = serverURL
        self.username = username
        self.password = password
        
        self.urlSession = URLSession.shared
    }
    
    func upload() {
        delegate?.uploading()

        var request = URLRequest(url: serverURL!)
        request.httpMethod = "POST"
        
        if (fileName == nil) {
            delegate?.error(error: "No file name set")
            return
        }
        if (data == nil) {
            delegate?.error(error: "No data to upload")
            return
        }

        addAuthToRequest(request: &request)
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let formData = formData(boundary: boundary)
        request.setValue(String(formData.count), forHTTPHeaderField: "Content-Length")
        
        urlSession.uploadTask(with: request, from: formData, completionHandler: completionHandler).resume()
    }
    
    func completionHandler(data: Data?, response: URLResponse?, error: Error?) -> Void {
        self.fileName = nil
        self.data = nil
        self.mimeType = nil

        if error != nil {
            delegate?.error(error:"\(String(describing: error!.localizedDescription))")
            return
        }
        
        guard let data = data else {
            delegate?.error(error: "No data from server")
            return
        }

        do {
            let decodedResponse  = try JSONDecoder().decode(FileCloudResponse.self, from: data)
            delegate?.uploaded(url: URL(string: "\(serverURL!)\(decodedResponse.url)")!)
        } catch let jsonError {
            delegate?.error(error: jsonError.localizedDescription)
        }
    }
    
    func formData(boundary: String) -> Data {
        var formData = Data()
        
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(String(describing: fileName!))\"\r\n".data(using: .utf8)!)
        if mimeType != nil && mimeType!.count > 0 {
            formData.append("Content-Type: \(String(describing: mimeType!))\r\n\r\n".data(using: .utf8)!)
        }
        formData.append(data!)
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return formData
    }
    
    func setFromFileURL(fileURL: URL) {
        self.fileName = fileURL.lastPathComponent
        self.data = try? Data(contentsOf: fileURL)
        
        let fileExtension = fileURL.pathExtension
        self.mimeType = UTTypeReference.init(filenameExtension: fileExtension)?.preferredMIMEType
    }
    
    func addAuthToRequest(request: inout URLRequest) {
        if username?.count ?? 0 > 0 {
            let loginString = "\(String(describing: username!)):\(String(describing: password!))"
            let loginData = Data(loginString.utf8)
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
    }
}
