import Foundation

extension URLRequest {
    mutating func setBasicAuth(username: String?, password: String?) {
        guard let username = username, !username.isEmpty,
              let password = password, !password.isEmpty else {
            return
        }

        let credentials = Data("\(username):\(password)".utf8).base64EncodedString()
        setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
    }
}
