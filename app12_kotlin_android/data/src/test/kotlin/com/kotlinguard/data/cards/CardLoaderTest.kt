package com.kotlinguard.data.cards

import com.kotlinguard.data.support.FileAssetSource
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class CardLoaderTest {
    private fun makeLoader(assetSource: FileAssetSource) =
        CardLoader(assetSource, ReferenceValidator(assetSource))

    /**
     * Regression test: the real `webapp` deck has 80 raw cards but only a
     * representative 14 are curated (see `CLAUDE.md`). Loading it must
     * succeed and silently skip every uncurated card, NOT throw — this is
     * the exact bug `CardLoader.buildSeed` had before this session's fix
     * (every uncurated card aborted the whole deck), mirroring the identical
     * fix made in `app11_swift_ios`'s Swift port of this same loader.
     */
    @Test
    fun loadingTheRealWebappDeckSkipsUncuratedCardsInsteadOfThrowing() {
        val loader = makeLoader(FileAssetSource.real)
        val webapp = DeckManifestEntry.all.first { it.edition == "webapp" }
        val seeds = loader.loadDeck(webapp)

        assertTrue(seeds.isNotEmpty())
        assertTrue("expected fewer than 80 raw cards — proves skipping happened", seeds.size < 80)
        assertTrue(seeds.any { it.cardId == "VE3" }) // a card that IS curated
    }

    @Test
    fun loadAllAcrossAllSixRealDecksSucceeds() {
        val loader = makeLoader(FileAssetSource.real)
        val seeds = loader.loadAll()
        assertTrue(seeds.isNotEmpty())

        val editions = seeds.map { it.edition }.toSet()
        assertEquals(setOf("webapp", "mobileapp", "companion", "eop", "mlsec", "dbd"), editions)
    }

    /** US-19/D-03: every card from the `dbd` deck must be a `DesignHarm`. */
    @Test
    fun everyDbdCardIsADesignHarm() {
        val loader = makeLoader(FileAssetSource.real)
        val dbd = DeckManifestEntry.all.first { it.isDesignHarmDeck }
        val seeds = loader.loadDeck(dbd)
        assertTrue(seeds.isNotEmpty())
        assertTrue(seeds.all { it.kind.isDesignHarm })
    }

    @Test
    fun faceCardsAreMarkedCritical() {
        val loader = makeLoader(FileAssetSource.real)
        val webapp = DeckManifestEntry.all.first { it.edition == "webapp" }
        val seeds = loader.loadDeck(webapp)
        val faceValues = setOf("K", "Q", "A")
        seeds.filter { it.value in faceValues }.forEach { assertTrue("${it.cardId} should be critical", it.isCritical) }
        seeds.filter { it.value !in faceValues }.forEach { assertTrue("${it.cardId} should not be critical", !it.isCritical) }
    }

    @Test
    fun throwsWhenACuratedCardHasAnInvalidSeverityString() {
        val assetSource = FileAssetSource.fixture(
            mapOf(
                "cornucopia/fixture-deck.yaml" to """
                    meta:
                      edition: "fixture"
                      component: "cards"
                      language: "en"
                      version: "1.0"
                    suits:
                    -
                      id: "FX"
                      name: "Fixture"
                      cards:
                      -
                        id: "FX1"
                        value: "2"
                        desc: "A fixture card."
                """.trimIndent(),
                "cornucopia/fixture.curation.json" to
                    """{ "FX1": { "severity": "not-a-real-severity", "owasp_refs": [], "mitre_refs": [] } }""",
                "ref-allowlists.json" to """{ "owasp_refs": [] }""",
                "mitre-atlas-allowlist.json" to """{ "mitre_refs": [] }"""
            )
        )
        val loader = makeLoader(assetSource)
        val entry = DeckManifestEntry("fixture-deck", "fixture.curation", "fixture", false)

        val error = assertThrows(CardDecodeError.MissingCuratedSeverity::class.java) {
            loader.loadDeck(entry)
        }
        assertEquals("FX1", error.cardId)
    }

    @Test
    fun throwsOnAnOrphanCurationEntry() {
        val assetSource = FileAssetSource.fixture(
            mapOf(
                "cornucopia/fixture-deck.yaml" to """
                    meta:
                      edition: "fixture"
                      component: "cards"
                      language: "en"
                      version: "1.0"
                    suits:
                    -
                      id: "FX"
                      name: "Fixture"
                      cards:
                      -
                        id: "FX1"
                        value: "2"
                        desc: "A fixture card."
                """.trimIndent(),
                "cornucopia/fixture.curation.json" to """
                    {
                      "FX1": { "severity": "high", "owasp_refs": [], "mitre_refs": [] },
                      "FX_DOES_NOT_EXIST": { "severity": "low", "owasp_refs": [], "mitre_refs": [] }
                    }
                """.trimIndent(),
                "ref-allowlists.json" to """{ "owasp_refs": [] }""",
                "mitre-atlas-allowlist.json" to """{ "mitre_refs": [] }"""
            )
        )
        val loader = makeLoader(assetSource)
        val entry = DeckManifestEntry("fixture-deck", "fixture.curation", "fixture", false)

        val error = assertThrows(CardDecodeError.OrphanCurationEntry::class.java) {
            loader.loadDeck(entry)
        }
        assertEquals("FX_DOES_NOT_EXIST", error.cardId)
    }

    @Test
    fun skipsACardWithNoCurationEntryAtAllRatherThanThrowing() {
        val assetSource = FileAssetSource.fixture(
            mapOf(
                "cornucopia/fixture-deck.yaml" to """
                    meta:
                      edition: "fixture"
                      component: "cards"
                      language: "en"
                      version: "1.0"
                    suits:
                    -
                      id: "FX"
                      name: "Fixture"
                      cards:
                      -
                        id: "FX1"
                        value: "2"
                        desc: "Curated card."
                      -
                        id: "FX2"
                        value: "3"
                        desc: "Uncurated card — must be skipped, not fatal."
                """.trimIndent(),
                "cornucopia/fixture.curation.json" to
                    """{ "FX1": { "severity": "high", "owasp_refs": [], "mitre_refs": [] } }""",
                "ref-allowlists.json" to """{ "owasp_refs": [] }""",
                "mitre-atlas-allowlist.json" to """{ "mitre_refs": [] }"""
            )
        )
        val loader = makeLoader(assetSource)
        val entry = DeckManifestEntry("fixture-deck", "fixture.curation", "fixture", false)

        val seeds = loader.loadDeck(entry)
        assertEquals(listOf("FX1"), seeds.map { it.cardId })
    }
}
