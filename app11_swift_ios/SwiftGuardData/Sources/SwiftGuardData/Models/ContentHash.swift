import Foundation
import SwiftData

@Model
public final class ContentHash {
    @Attribute(.unique) public var fileName: String
    public var sha256Hash: String
    public var verifiedAt: Date
    public var isValid: Bool
    public var verifiedBy: String

    public init(fileName: String, sha256Hash: String, verifiedAt: Date, isValid: Bool, verifiedBy: String = "swiftguard-integrity-service") {
        self.fileName = fileName
        self.sha256Hash = sha256Hash
        self.verifiedAt = verifiedAt
        self.isValid = isValid
        self.verifiedBy = verifiedBy
    }
}
