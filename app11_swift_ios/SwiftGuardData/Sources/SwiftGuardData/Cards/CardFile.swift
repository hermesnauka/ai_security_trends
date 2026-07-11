import Foundation

/// D-06: Swift's synthesized `Decodable` conformance silently ignores
/// unrecognized keys — the opposite default from `app10_csharp_react`'s
/// `YamlDotNet`. Every type below hand-writes `init(from:)` with a
/// `DynamicKey`-based container specifically to recover the "reject
/// unrecognized fields" guarantee other siblings get from a derive macro or
/// library default, per §0.1: the raw YAML shape is only
/// meta{edition,component,language,version} / suits[{id,name,cards[{id,value,url,desc,misc}]}].
struct RawCard: Decodable, Sendable {
    static let allowedKeys: Set<String> = ["id", "value", "url", "desc", "misc"]

    let id: String
    let value: String
    let url: String?
    let desc: String
    let misc: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        let unrecognized = Set(container.allKeys.map(\.stringValue)).subtracting(Self.allowedKeys)
        guard unrecognized.isEmpty else {
            throw CardDecodeError.unrecognizedFields(unrecognized)
        }

        guard let idKey = DynamicKey(stringValue: "id"),
              let valueKey = DynamicKey(stringValue: "value"),
              let descKey = DynamicKey(stringValue: "desc") else {
            throw CardDecodeError.missingRequiredField("id/value/desc")
        }

        id = try container.decode(String.self, forKey: idKey)
        value = try container.decode(String.self, forKey: valueKey)
        desc = try container.decode(String.self, forKey: descKey)
        url = try container.decodeIfPresent(String.self, forKey: DynamicKey(stringValue: "url")!)
        misc = try container.decodeIfPresent(String.self, forKey: DynamicKey(stringValue: "misc")!)
    }
}

/// The "Common"/metadata suit (e.g. deck title/version blurb) has a
/// `sentences` key instead of `cards` — it carries no threat data. `cards`
/// is optional for exactly that reason, and such suits are skipped during
/// extraction, not treated as a decode error (mirrors app09's Card_Loader).
struct RawSuit: Decodable, Sendable {
    static let allowedKeys: Set<String> = ["id", "name", "cards", "sentences"]

    let id: String
    let name: String
    let cards: [RawCard]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        let unrecognized = Set(container.allKeys.map(\.stringValue)).subtracting(Self.allowedKeys)
        guard unrecognized.isEmpty else {
            throw CardDecodeError.unrecognizedFields(unrecognized)
        }

        id = try container.decode(String.self, forKey: DynamicKey(stringValue: "id")!)
        name = try container.decode(String.self, forKey: DynamicKey(stringValue: "name")!)
        cards = try container.decodeIfPresent([RawCard].self, forKey: DynamicKey(stringValue: "cards")!)
    }
}

struct RawMeta: Decodable, Sendable {
    static let allowedKeys: Set<String> = ["edition", "component", "language", "version"]

    let edition: String
    let component: String
    let language: String
    let version: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        let unrecognized = Set(container.allKeys.map(\.stringValue)).subtracting(Self.allowedKeys)
        guard unrecognized.isEmpty else {
            throw CardDecodeError.unrecognizedFields(unrecognized)
        }

        edition = try container.decode(String.self, forKey: DynamicKey(stringValue: "edition")!)
        component = try container.decode(String.self, forKey: DynamicKey(stringValue: "component")!)
        language = try container.decode(String.self, forKey: DynamicKey(stringValue: "language")!)
        version = try container.decode(String.self, forKey: DynamicKey(stringValue: "version")!)
    }
}

struct CardFile: Decodable, Sendable {
    static let allowedKeys: Set<String> = ["meta", "suits"]

    let meta: RawMeta
    let suits: [RawSuit]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        let unrecognized = Set(container.allKeys.map(\.stringValue)).subtracting(Self.allowedKeys)
        guard unrecognized.isEmpty else {
            throw CardDecodeError.unrecognizedFields(unrecognized)
        }

        meta = try container.decode(RawMeta.self, forKey: DynamicKey(stringValue: "meta")!)
        suits = try container.decode([RawSuit].self, forKey: DynamicKey(stringValue: "suits")!)
    }
}
