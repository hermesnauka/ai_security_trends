import Foundation
import Yams

/// D-06/§0.1: decodes a deck's raw YAML (allow-list enforced, D-06), merges
/// in curated severity/refs (never read from the YAML itself), and produces
/// `CornucopiaCard`-ready data. Mirrors app09's `Card_Loader`.
public struct CardLoader: Sendable {
    private let referenceValidator: ReferenceValidator
    private let bundle: Bundle

    public init(referenceValidator: ReferenceValidator, bundle: Bundle = .main) {
        self.referenceValidator = referenceValidator
        self.bundle = bundle
    }

    public struct CardSeed: Sendable {
        public let cardId: String
        public let suitCode: String
        public let suitName: String
        public let edition: String
        public let value: String
        public let kind: CardKind
        public let descriptionEn: String
        public let descriptionPl: String
        public let miscNote: String?
        public let sourceUrl: String?
        public let owaspRefs: [String]
        public let mitreRefs: [String]
        public let contentSha256: String
        public let isCritical: Bool
    }

    /// Loads every deck in `DeckManifestEntry.all`, then — only once every
    /// deck's card IDs are known — checks the shared `pl.cards.json`
    /// translations file for an orphaned key (AC-19-equivalent), since that
    /// file isn't scoped to a single deck and can't be checked per-deck
    /// without rejecting every other deck's legitimate entries.
    public func loadAll() throws -> [CardSeed] {
        var allSeeds: [CardSeed] = []
        var allCardIds: Set<String> = []

        for entry in DeckManifestEntry.all {
            let seeds = try loadDeck(entry)
            for seed in seeds {
                allCardIds.insert(seed.cardId)
            }
            allSeeds.append(contentsOf: seeds)
        }

        guard let translationsUrl = bundle.url(forResource: "pl.cards", withExtension: "json", subdirectory: "Cornucopia/Translations") else {
            return allSeeds
        }
        let translations = try CurationFileLoader.loadTranslations(from: translationsUrl)
        for cardId in translations.keys where !allCardIds.contains(cardId) {
            throw CardDecodeError.orphanCurationEntry(cardId: cardId, file: "pl.cards.json")
        }

        return allSeeds
    }

    public func loadDeck(_ entry: DeckManifestEntry) throws -> [CardSeed] {
        guard let yamlUrl = bundle.url(forResource: entry.yamlFileName, withExtension: "yaml", subdirectory: "Cornucopia") else {
            throw CardDecodeError.missingRequiredField("deck file not found: \(entry.yamlFileName).yaml")
        }
        let yamlString = try String(contentsOf: yamlUrl, encoding: .utf8)
        let cardFile = try YAMLDecoder().decode(CardFile.self, from: yamlString)

        var rawCards: [(card: RawCard, suitCode: String, suitName: String)] = []
        for suit in cardFile.suits {
            // The "Common"/metadata suit has no `cards` array at all — it
            // carries no threat data and is skipped, not a decode error.
            guard let cards = suit.cards else { continue }
            for card in cards {
                rawCards.append((card, suit.id, suit.name))
            }
        }

        let knownIds = Set(rawCards.map(\.card.id))

        var curation: [String: CurationEntry] = [:]
        if let curationUrl = bundle.url(forResource: entry.curationFileName, withExtension: "json", subdirectory: "Cornucopia") {
            curation = try CurationFileLoader.load(from: curationUrl)
            for cardId in curation.keys where !knownIds.contains(cardId) {
                throw CardDecodeError.orphanCurationEntry(cardId: cardId, file: entry.curationFileName)
            }
        }

        var translations: [String: String] = [:]
        if let translationsUrl = bundle.url(forResource: "pl.cards", withExtension: "json", subdirectory: "Cornucopia/Translations") {
            translations = try CurationFileLoader.loadTranslations(from: translationsUrl)
        }

        return try rawCards.map { entryTuple in
            try buildSeed(
                card: entryTuple.card,
                suitCode: entryTuple.suitCode,
                suitName: entryTuple.suitName,
                manifestEntry: entry,
                curationEntry: curation[entryTuple.card.id],
                translation: translations[entryTuple.card.id]
            )
        }
    }

    private func buildSeed(
        card: RawCard,
        suitCode: String,
        suitName: String,
        manifestEntry: DeckManifestEntry,
        curationEntry: CurationEntry?,
        translation: String?
    ) throws -> CardSeed {
        let kind: CardKind
        if manifestEntry.isDesignHarmDeck {
            kind = .designHarm
        } else {
            guard let severityString = curationEntry?.severity, let severity = Severity(rawValue: severityString) else {
                throw CardDecodeError.missingCuratedSeverity(cardId: card.id)
            }
            kind = .technicalThreat(severity: severity)
        }

        let owaspRefs = curationEntry?.owaspRefs ?? []
        let mitreRefs = curationEntry?.mitreRefs ?? []
        try referenceValidator.assertOwaspRefsValid(owaspRefs, cardId: card.id)
        try referenceValidator.assertMitreRefsValid(mitreRefs, cardId: card.id)

        let descriptionEn = card.desc
        let descriptionPl = translation ?? descriptionEn // FR-18.6: fall back to English, never blank

        let contentSha256 = Self.sha256Hex(
            "\(card.id)|\(card.value)|\(card.url ?? "")|\(descriptionEn)|\(card.misc ?? "")"
        )

        return CardSeed(
            cardId: card.id,
            suitCode: suitCode,
            suitName: suitName,
            edition: manifestEntry.edition,
            value: card.value,
            kind: kind,
            descriptionEn: descriptionEn,
            descriptionPl: descriptionPl,
            miscNote: card.misc,
            sourceUrl: card.url,
            owaspRefs: owaspRefs,
            mitreRefs: mitreRefs,
            contentSha256: contentSha256,
            isCritical: ["K", "Q", "A"].contains(card.value)
        )
    }

    private static func sha256Hex(_ input: String) -> String {
        Hashing.sha256Hex(input)
    }
}
