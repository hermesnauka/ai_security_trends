import Foundation
import SwiftData

/// All six YAML decks — see D-03 for `CardKind`, D-06 for how curation
/// (severity/owaspRefs/mitreRefs) is merged in rather than read from the raw
/// YAML, which has no such fields at all (PLAN.md §0.1).
@Model
public final class CornucopiaCard {
    @Attribute(.unique) public var cardId: String       // "VE3", "LLM4", "SCO2"
    public var suitCode: String
    public var suitName: String
    public var edition: String                           // webapp, mobileapp, companion, eop, mlsec, dbd
    public var value: String                              // "2".."10","J","Q","K","A"
    public var kind: CardKind                              // D-03: technicalThreat(severity) | designHarm
    public var descriptionEn: String
    public var descriptionPl: String
    public var miscNote: String?
    public var sourceUrl: String?
    public var owaspRefs: [String]
    public var mitreRefs: [String]
    public var contentSha256: String
    public var isCritical: Bool
    @Relationship(deleteRule: .cascade, inverse: \Mitigation.card) public var mitigations: [Mitigation] = []

    public init(
        cardId: String,
        suitCode: String,
        suitName: String,
        edition: String,
        value: String,
        kind: CardKind,
        descriptionEn: String,
        descriptionPl: String,
        miscNote: String?,
        sourceUrl: String?,
        owaspRefs: [String],
        mitreRefs: [String],
        contentSha256: String,
        isCritical: Bool
    ) {
        self.cardId = cardId
        self.suitCode = suitCode
        self.suitName = suitName
        self.edition = edition
        self.value = value
        self.kind = kind
        self.descriptionEn = descriptionEn
        self.descriptionPl = descriptionPl
        self.miscNote = miscNote
        self.sourceUrl = sourceUrl
        self.owaspRefs = owaspRefs
        self.mitreRefs = mitreRefs
        self.contentSha256 = contentSha256
        self.isCritical = isCritical
    }

    public func localizedDescription(_ locale: AppLocale) -> String {
        locale == .polish && !descriptionPl.isEmpty ? descriptionPl : descriptionEn
    }
}
