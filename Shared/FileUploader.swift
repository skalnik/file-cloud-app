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
    
    weak var delegate: UploadDelegate?
    
    /// Reports the end of one upload. The delegate hears the same result.
    typealias Completion = (Result<URL, Error>) -> Void

    struct FileCloudResponse: Codable {
        var url: String
    }
    
    init(serverURL: URL?, username: String?, password: String?) {
        self.serverURL = serverURL
        self.username = username
        self.password = password
        
        self.urlSession = URLSession.shared
    }
    
    func upload(fileURL: URL, completion: Completion? = nil) {
        delegate?.uploading()

        guard let serverURL = serverURL else {
            report(error: "Server URL is not configured", to: completion)
            return
        }

        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"

        if let username = username, !username.isEmpty,
           let password = password, !password.isEmpty {
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
            report(error: error.localizedDescription, to: completion)
            return
        }

        urlSession.uploadTask(with: request, fromFile: bodyURL) { data, response, error in
            try? FileManager.default.removeItem(at: bodyURL)
            self.completionHandler(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    func completionHandler(data: Data?, response: URLResponse?, error: Error?,
                           completion: Completion? = nil) -> Void {
        if let error = error {
            report(error: error.localizedDescription, to: completion)
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            report(error: "No response from the server", to: completion)
            return
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            report(error: FileUploader.message(forStatusCode: httpResponse.statusCode), to: completion)
            return
        }

        guard let data = data else {
            report(error: "No data from server", to: completion)
            return
        }

        do {
            let decodedResponse = try JSONDecoder().decode(FileCloudResponse.self, from: data)
            guard let serverURL = serverURL else {
                report(error: "Server URL is not configured", to: completion)
                return
            }
            let uploadedURL = serverURL.appendingPathComponent(decodedResponse.url)
            delegate?.uploaded(url: uploadedURL)
            completion?(.success(uploadedURL))
        } catch {
            report(error: "Could not read the response of the server", to: completion)
        }
    }

    /// Tells the delegate and the completion about the same failure.
    private func report(error message: String, to completion: Completion?) {
        delegate?.error(error: message)
        completion?(.failure(UploadError.failed(message)))
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

enum UploadError: LocalizedError {
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .failed(let message): message
        }
    }
}
