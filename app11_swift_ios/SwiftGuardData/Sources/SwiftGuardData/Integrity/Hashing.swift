import CryptoKit
import Foundation

/// Thin wrapper over Apple's own `CryptoKit` — no third-party crypto
/// dependency needed for SHA-256, unlike every server-based sibling that had
/// to pick a library for this.
enum Hashing {
    static func sha256Hex(_ input: String) -> String {
        sha256Hex(Data(input.utf8))
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
