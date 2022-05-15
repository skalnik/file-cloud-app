//
//  FileUploader.swift
//  File Cloud
//
//  Created by Mike Skalnik on 5/12/22.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

protocol UploadDelegate {
    func error(error: String)
    func uploaded(url: URL)
}

class FileUploader: NSObject {
    static let shared = FileUploader()
    var serverURL: URL?
    var username: String?
    var password: String?
    
    let urlSession: URLSession
    
    var fileURL: URL?
    
    var delegate: UploadDelegate?
    
    struct FileCloudResponse: Codable {
        var url: String
    }
    
    override private init() {
        self.serverURL = nil
        self.username = nil
        self.password = nil
        self.fileURL = nil
        
        self.urlSession = URLSession.shared
        
        super.init()
    }
    
    func upload() {
        var request = URLRequest(url: serverURL!)
        request.httpMethod = "POST"
        
        guard let fileURL = fileURL else {
            return
        }

        if username?.count ?? 0 > 0 {
            let loginString = "\(String(describing: username)):\(String(describing: password))"
            let loginData = Data(loginString.utf8)
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let formData = formData(boundary: boundary, fileURL: fileURL)
        request.setValue(String(formData.count), forHTTPHeaderField: "Content-Length")
        
        urlSession.uploadTask(with: request, from: formData, completionHandler: completionHandler).resume()
    }
    
    func completionHandler(data: Data?, response: URLResponse?, error: Error?) -> Void {
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
        formData.append("Content-Type: \(String(describing: mimeType(fileURL: fileURL)))\r\n\r\n".data(using: .utf8)!)
        formData.append(fileData!)
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return formData
    }
    
    func mimeType(fileURL: URL) -> String {
        let fileExtension = fileURL.pathExtension
        
        return UTTypeReference.init(filenameExtension: fileExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
}
