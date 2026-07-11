import Foundation

/// SR-07-equivalent: owaspRefs/mitreRefs values are validated against
/// allowlists bundled as app resources before any card is written to
/// SwiftData — the same guard app09's Reference_Validator provides, since
/// every one of these values is curated content (PLAN.md §0.1), never
/// extracted from the raw YAML.
public struct ReferenceValidator: Sendable {
    private let owaspAllowlist: Set<String>
    private let mitreAllowlist: Set<String>

    public init(bundle: Bundle = .main) throws {
        owaspAllowlist = try Self.loadAllowlist(named: "ref-allowlists", key: "owasp_refs", bundle: bundle)
        mitreAllowlist = try Self.loadAllowlist(named: "mitre-atlas-allowlist", key: "mitre_refs", bundle: bundle)
    }

    public func assertOwaspRefsValid(_ refs: [String], cardId: String) throws {
        for ref in refs where !owaspAllowlist.contains(ref) {
            throw CardDecodeError.unknownReference(value: ref, field: "owasp_refs", cardId: cardId)
        }
    }

    public func assertMitreRefsValid(_ refs: [String], cardId: String) throws {
        for ref in refs where !mitreAllowlist.contains(ref) {
            throw CardDecodeError.unknownReference(value: ref, field: "mitre_refs", cardId: cardId)
        }
    }

    private static func loadAllowlist(named name: String, key: String, bundle: Bundle) throws -> Set<String> {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        struct AllowlistFile: Decodable {
            let values: [String]
            enum CodingKeys: String, CodingKey {
                case owaspRefs = "owasp_refs"
                case mitreRefs = "mitre_refs"
            }
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                if let owasp = try container.decodeIfPresent([String].self, forKey: .owaspRefs) {
                    values = owasp
                } else {
                    values = try container.decode([String].self, forKey: .mitreRefs)
                }
            }
        }
        return Set(try JSONDecoder().decode(AllowlistFile.self, from: data).values)
    }
}
