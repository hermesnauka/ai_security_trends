import Foundation
import SwiftData

@Model
public final class CrossReference {
    public var sourceThreatCode: String
    public var targetThreatCode: String
    public var targetThreatTitle: String
    public var relationshipType: RelationshipType
    public var referenceDescription: String

    public init(
        sourceThreatCode: String,
        targetThreatCode: String,
        targetThreatTitle: String,
        relationshipType: RelationshipType,
        referenceDescription: String
    ) {
        self.sourceThreatCode = sourceThreatCode
        self.targetThreatCode = targetThreatCode
        self.targetThreatTitle = targetThreatTitle
        self.relationshipType = relationshipType
        self.referenceDescription = referenceDescription
    }
}
