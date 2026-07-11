/// Mirrors app09's `Card_Loader::deck_manifest()` — the six decks, their
/// curation files, and which one (`dbd`) is the design-harm deck whose
/// `CardKind`/severity is forced by file identity, never read from a field.
public struct DeckManifestEntry: Sendable {
    public let yamlFileName: String
    public let curationFileName: String
    public let edition: String
    public let isDesignHarmDeck: Bool

    public static let all: [DeckManifestEntry] = [
        DeckManifestEntry(yamlFileName: "webapp-cards-3.0-en", curationFileName: "webapp.curation", edition: "webapp", isDesignHarmDeck: false),
        DeckManifestEntry(yamlFileName: "mobileapp-cards-1.1-en", curationFileName: "mobileapp.curation", edition: "mobileapp", isDesignHarmDeck: false),
        DeckManifestEntry(yamlFileName: "companion-llm-cards-1.0-en", curationFileName: "companion.curation", edition: "companion", isDesignHarmDeck: false),
        DeckManifestEntry(yamlFileName: "stride-eop-cards-5.0-en", curationFileName: "stride-eop.curation", edition: "eop", isDesignHarmDeck: false),
        DeckManifestEntry(yamlFileName: "mlsec-cards-1.0-en", curationFileName: "mlsec.curation", edition: "mlsec", isDesignHarmDeck: false),
        DeckManifestEntry(yamlFileName: "dbd-cards-1.0-en", curationFileName: "dbd.curation", edition: "dbd", isDesignHarmDeck: true)
    ]
}
