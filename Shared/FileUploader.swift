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
    
    var fileURL: URL?
    
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
        let formData = formData(boundary: boundary, fileURL: fileURL)
        request.setValue(String(formData.count), forHTTPHeaderField: "Content-Length")
        
        urlSession.uploadTask(with: request, from: formData, completionHandler: completionHandler).resume()
    }
    
    func completionHandler(data: Data?, response: URLResponse?, error: Error?) -> Void {
        self.fileURL = nil

        if error != nil {
            delegate?.error(error:"Error took place \(String(describing: error))")
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
    
    func formData(boundary: String, fileURL: URL) -> Data {
        var formData = Data()
        let fileName = fileURL.lastPathComponent
        let fileData = try? Data(contentsOf: fileURL)
        
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        let mimeType = mimeType(fileURL: fileURL)
        if mimeType != nil {
            formData.append("Content-Type: \(String(describing: mimeType!))\r\n\r\n".data(using: .utf8)!)
        }
        formData.append(fileData!)
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return formData
    }
    
    func addAuthToRequest(request: inout URLRequest){
        if username?.count ?? 0 > 0 {
            let loginString = "\(String(describing: username!)):\(String(describing: password!))"
            let loginData = Data(loginString.utf8)
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
    }
    
    func mimeType(fileURL: URL) -> String? {
        let fileExtension = fileURL.pathExtension
        
        return UTTypeReference.init(filenameExtension: fileExtension)?.preferredMIMEType
    }
}
