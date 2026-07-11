import Foundation

/// One curated entry per card_id — severity/owaspRefs/mitreRefs never exist
/// in the raw YAML (PLAN.md §0.1); this is the reviewed file that supplies
/// them, merged with the raw card by `CardLoader`.
struct CurationEntry: Decodable, Sendable {
    let severity: String?
    let owaspRefs: [String]
    let mitreRefs: [String]

    enum CodingKeys: String, CodingKey {
        case severity
        case owaspRefs = "owasp_refs"
        case mitreRefs = "mitre_refs"
    }
}

enum CurationFileLoader {
    /// `_comment` is a reserved top-level key holding a plain string, not a
    /// card entry — it must be filtered out BEFORE typed decoding, since its
    /// value shape doesn't match `CurationEntry` at all and a uniform
    /// `[String: CurationEntry]` decode would throw on it first.
    private static let reservedKeys: Set<String> = ["_comment"]

    static func load(from url: URL) throws -> [String: CurationEntry] {
        let data = try Data(contentsOf: url)

        guard let rawObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CardDecodeError.missingRequiredField("curation file root must be a JSON object")
        }

        var result: [String: CurationEntry] = [:]
        for (cardId, rawValue) in rawObject {
            if reservedKeys.contains(cardId) {
                continue
            }
            let entryData = try JSONSerialization.data(withJSONObject: rawValue)
            result[cardId] = try JSONDecoder().decode(CurationEntry.self, from: entryData)
        }
        return result
    }

    static func loadTranslations(from url: URL) throws -> [String: String] {
        let data = try Data(contentsOf: url)

        guard let rawObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CardDecodeError.missingRequiredField("translations file root must be a JSON object")
        }

        var result: [String: String] = [:]
        for (cardId, rawValue) in rawObject {
            if reservedKeys.contains(cardId) {
                continue
            }
            if let text = rawValue as? String {
                result[cardId] = text
            }
        }
        return result
    }
}
