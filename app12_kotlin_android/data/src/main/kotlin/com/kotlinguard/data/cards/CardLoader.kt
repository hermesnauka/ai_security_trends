package com.kotlinguard.data.cards

import com.kotlinguard.data.assets.AssetSource
import com.kotlinguard.data.integrity.Hashing
import com.kotlinguard.data.model.CardKind
import com.kotlinguard.data.model.Severity

/**
 * D-06/§0.1: decodes a deck's raw YAML (allow-list enforced via kaml's
 * `strictMode`, D-06), merges in curated severity/refs (never read from the
 * YAML itself), and produces card-seed data ready for a Room insert.
 * Mirrors app09's `Card_Loader` and app11's `CardLoader`.
 */
class CardLoader(
    private val assetSource: AssetSource,
    private val referenceValidator: ReferenceValidator
) {
    data class CardSeed(
        val cardId: String,
        val suitCode: String,
        val suitName: String,
        val edition: String,
        val value: String,
        val kind: CardKind,
        val descriptionEn: String,
        val descriptionPl: String,
        val miscNote: String?,
        val sourceUrl: String?,
        val owaspRefs: List<String>,
        val mitreRefs: List<String>,
        val contentSha256: String,
        val isCritical: Boolean
    )

    /**
     * Loads every deck in `DeckManifestEntry.all`, then — only once every
     * deck's card IDs are known — checks the shared `pl.cards.json`
     * translations file for an orphaned key (AC-19-equivalent), since that
     * file isn't scoped to a single deck and can't be checked per-deck
     * without rejecting every other deck's legitimate entries.
     */
    fun loadAll(): List<CardSeed> {
        val allSeeds = mutableListOf<CardSeed>()
        val allCardIds = mutableSetOf<String>()

        for (entry in DeckManifestEntry.all) {
            val seeds = loadDeck(entry)
            allCardIds += seeds.map { it.cardId }
            allSeeds += seeds
        }

        val translationsText = assetSource.readText("cornucopia/translations/pl.cards.json") ?: return allSeeds
        val translations = CurationFileLoader.loadTranslations(translationsText)
        for (cardId in translations.keys) {
            if (cardId !in allCardIds) throw CardDecodeError.OrphanCurationEntry(cardId, "pl.cards.json")
        }

        return allSeeds
    }

    fun loadDeck(entry: DeckManifestEntry): List<CardSeed> {
        val yamlText = assetSource.readText("cornucopia/${entry.yamlFileName}.yaml")
            ?: throw CardDecodeError.MissingRequiredField("deck file not found: ${entry.yamlFileName}.yaml")
        val cardFile = cardYaml.decodeFromString(CardFile.serializer(), yamlText)

        val rawCards = mutableListOf<Triple<RawCard, String, String>>()
        for (suit in cardFile.suits) {
            // The "Common"/metadata suit has no `cards` array at all — it
            // carries no threat data and is skipped, not a decode error.
            val cards = suit.cards ?: continue
            for (card in cards) rawCards += Triple(card, suit.id, suit.name)
        }

        val knownIds = rawCards.map { it.first.id }.toSet()

        val curationText = assetSource.readText("cornucopia/${entry.curationFileName}.json")
        val curation = if (curationText != null) {
            val loaded = CurationFileLoader.load(curationText)
            for (cardId in loaded.keys) {
                if (cardId !in knownIds) throw CardDecodeError.OrphanCurationEntry(cardId, entry.curationFileName)
            }
            loaded
        } else emptyMap()

        val translationsText = assetSource.readText("cornucopia/translations/pl.cards.json")
        val translations = if (translationsText != null) CurationFileLoader.loadTranslations(translationsText) else emptyMap()

        return rawCards.map { (card, suitCode, suitName) ->
            buildSeed(card, suitCode, suitName, entry, curation[card.id], translations[card.id])
        }
    }

    private fun buildSeed(
        card: RawCard,
        suitCode: String,
        suitName: String,
        manifestEntry: DeckManifestEntry,
        curationEntry: CurationEntry?,
        translation: String?
    ): CardSeed {
        val kind: CardKind = if (manifestEntry.isDesignHarmDeck) {
            CardKind.DesignHarm
        } else {
            val severityString = curationEntry?.severity
                ?: throw CardDecodeError.MissingCuratedSeverity(card.id)
            val severity = Severity.entries.find { it.name.equals(severityString, ignoreCase = true) }
                ?: throw CardDecodeError.MissingCuratedSeverity(card.id)
            CardKind.TechnicalThreat(severity)
        }

        val owaspRefs = curationEntry?.owasp_refs ?: emptyList()
        val mitreRefs = curationEntry?.mitre_refs ?: emptyList()
        referenceValidator.assertOwaspRefsValid(owaspRefs, card.id)
        referenceValidator.assertMitreRefsValid(mitreRefs, card.id)

        val descriptionEn = card.desc
        val descriptionPl = translation ?: descriptionEn // FR-18.6: fall back to English, never blank

        val contentSha256 = Hashing.sha256Hex(
            "${card.id}|${card.value}|${card.url ?: ""}|$descriptionEn|${card.misc ?: ""}"
        )

        return CardSeed(
            cardId = card.id,
            suitCode = suitCode,
            suitName = suitName,
            edition = manifestEntry.edition,
            value = card.value,
            kind = kind,
            descriptionEn = descriptionEn,
            descriptionPl = descriptionPl,
            miscNote = card.misc,
            sourceUrl = card.url,
            owaspRefs = owaspRefs,
            mitreRefs = mitreRefs,
            contentSha256 = contentSha256,
            isCritical = card.value in setOf("K", "Q", "A")
        )
    }
}
