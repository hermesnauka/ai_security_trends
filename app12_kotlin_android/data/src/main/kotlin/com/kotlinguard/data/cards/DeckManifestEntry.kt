package com.kotlinguard.data.cards

/**
 * Mirrors app09's `Card_Loader::deck_manifest()` and app11's
 * `DeckManifestEntry` — the six decks, their curation files, and which one
 * (`dbd`) is the design-harm deck whose `CardKind`/severity is forced by
 * file identity, never read from a field.
 */
data class DeckManifestEntry(
    val yamlFileName: String,
    val curationFileName: String,
    val edition: String,
    val isDesignHarmDeck: Boolean
) {
    companion object {
        val all: List<DeckManifestEntry> = listOf(
            DeckManifestEntry("webapp-cards-3.0-en", "webapp.curation", "webapp", false),
            DeckManifestEntry("mobileapp-cards-1.1-en", "mobileapp.curation", "mobileapp", false),
            DeckManifestEntry("companion-llm-cards-1.0-en", "companion.curation", "companion", false),
            DeckManifestEntry("stride-eop-cards-5.0-en", "stride-eop.curation", "eop", false),
            DeckManifestEntry("mlsec-cards-1.0-en", "mlsec.curation", "mlsec", false),
            DeckManifestEntry("dbd-cards-1.0-en", "dbd.curation", "dbd", true)
        )
    }
}
