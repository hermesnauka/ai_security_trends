import Foundation
import SwiftData

/// The only user-generated, sync-eligible data in this app (D-07).
@Model
public final class Bookmark {
    @Attribute(.unique) public var threatOrCardCode: String
    public var createdAt: Date
    public var cloudKitRecordName: String?   // set only if CloudKit sync (D-07) is enabled

    public init(threatOrCardCode: String, createdAt: Date = Date(), cloudKitRecordName: String? = nil) {
        self.threatOrCardCode = threatOrCardCode
        self.createdAt = createdAt
        self.cloudKitRecordName = cloudKitRecordName
    }
}
