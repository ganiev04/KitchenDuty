import CryptoKit
import Foundation

enum PasswordHasher {
    static func makeSalt() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }

    static func hash(password: String, salt: String) -> String {
        let payload = Data((salt + ":" + password).utf8)
        let digest = SHA256.hash(data: payload)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func matches(password: String, salt: String, hash: String) -> Bool {
        self.hash(password: password, salt: salt) == hash
    }
}
