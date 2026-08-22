//
//  FileUploader.swift
//  File Cloud
//
//  Created by Mike Skalnik on 5/12/22.
//

import Foundation
import UniformTypeIdentifiers

protocol UploadDelegate: AnyObject {
    func error(error: String)
    func uploaded(url: URL)
    func uploading()
}

class FileUploader: NSObject {
    var serverURL: URL?
    var username: String?
    var password: String?
    
    static let chunkSize = 1 << 20  // 1 MB

    let urlSession: URLSession
    
    var fileURL: URL?
    
    weak var delegate: UploadDelegate?
    
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

        guard let serverURL = serverURL else {
            delegate?.error(error: "Server URL is not configured")
            return
        }

        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"

        guard let fileURL = fileURL else {
            delegate?.error(error: "No file selected")
            return
        }

        if let username = username, !username.isEmpty,
           let password = password {
            let loginString = "\(username):\(password)"
            let loginData = Data(loginString.utf8)
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let bodyURL: URL
        do {
            bodyURL = try multipartBody(boundary: boundary, fileURL: fileURL)
        } catch {
            delegate?.error(error: error.localizedDescription)
            return
        }

        urlSession.uploadTask(with: request, fromFile: bodyURL) { data, response, error in
            try? FileManager.default.removeItem(at: bodyURL)
            self.completionHandler(data: data, response: response, error: error)
        }.resume()
    }
    
    func completionHandler(data: Data?, response: URLResponse?, error: Error?) -> Void {
        self.fileURL = nil

        if let error = error {
            delegate?.error(error: error.localizedDescription)
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            delegate?.error(error: "No response from the server")
            return
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            delegate?.error(error: FileUploader.message(forStatusCode: httpResponse.statusCode))
            return
        }

        guard let data = data else {
            delegate?.error(error: "No data from server")
            return
        }

        do {
            let decodedResponse = try JSONDecoder().decode(FileCloudResponse.self, from: data)
            guard let serverURL = serverURL else {
                delegate?.error(error: "Server URL is not configured")
                return
            }
            let uploadedURL = serverURL.appendingPathComponent(decodedResponse.url)
            delegate?.uploaded(url: uploadedURL)
        } catch {
            delegate?.error(error: "Could not read the response of the server")
        }
    }

    static func message(forStatusCode statusCode: Int) -> String {
        switch statusCode {
        case 401, 403: "Check your username and password"
        case 404: "The server URL is not correct"
        default: "The server returned an error (HTTP \(statusCode))"
        }
    }
    
    func multipartBody(boundary: String, fileURL: URL) throws -> URL {
        let bodyURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("upload-\(UUID().uuidString)")

        guard FileManager.default.createFile(atPath: bodyURL.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown)
        }

        do {
            let source = try FileHandle(forReadingFrom: fileURL)
            defer { try? source.close() }

            let body = try FileHandle(forWritingTo: bodyURL)
            defer { try? body.close() }

            var header = "--\(boundary)\r\n"
            header += "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n"
            if let mimeType = mimeType(fileURL: fileURL) {
                header += "Content-Type: \(mimeType)\r\n"
            }
            header += "\r\n"
            try body.write(contentsOf: Data(header.utf8))

            var moreData = true
            while moreData {
                try autoreleasepool {
                    guard let chunk = try source.read(upToCount: FileUploader.chunkSize),
                          !chunk.isEmpty else {
                        moreData = false
                        return
                    }
                    try body.write(contentsOf: chunk)
                }
            }

            try body.write(contentsOf: Data("\r\n--\(boundary)--\r\n".utf8))
        } catch {
            try? FileManager.default.removeItem(at: bodyURL)
            throw error
        }

        return bodyURL
    }
    
    func mimeType(fileURL: URL) -> String? {
        let fileExtension = fileURL.pathExtension
        
        return UTTypeReference.init(filenameExtension: fileExtension)?.preferredMIMEType
    }
}
