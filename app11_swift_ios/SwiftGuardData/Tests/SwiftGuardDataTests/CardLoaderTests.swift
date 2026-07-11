import XCTest
@testable import SwiftGuardData

final class CardLoaderTests: XCTestCase {
    private func makeLoader(bundle: Bundle) throws -> CardLoader {
        CardLoader(referenceValidator: try ReferenceValidator(bundle: bundle), bundle: bundle)
    }

    // MARK: - Against the REAL bundled webapp deck (via Bundle.module)

    /// Regression test: the real `webapp` deck has 80 raw cards but only a
    /// representative 14 are curated (see `CLAUDE.md`). Loading it must
    /// succeed and silently skip every uncurated card, NOT throw — this is
    /// the exact bug `CardLoader.buildSeed` had before this session's fix
    /// (every uncurated card aborted the whole deck).
    func testLoadingTheRealWebappDeckSkipsUncuratedCardsInsteadOfThrowing() throws {
        let loader = try makeLoader(bundle: .module)
        let webapp = DeckManifestEntry.all.first { $0.edition == "webapp" }!
        let seeds = try loader.loadDeck(webapp)

        XCTAssertGreaterThan(seeds.count, 0)
        XCTAssertLessThan(seeds.count, 80) // fewer than the 80 raw cards — proves skipping happened
        XCTAssertTrue(seeds.contains { $0.cardId == "VE3" }) // a card that IS curated
    }

    func testLoadAllAcrossAllSixRealDecksSucceeds() throws {
        let loader = try makeLoader(bundle: .module)
        let seeds = try loader.loadAll()
        XCTAssertGreaterThan(seeds.count, 0)

        let editions = Set(seeds.map(\.edition))
        XCTAssertEqual(editions, ["webapp", "mobileapp", "companion", "eop", "mlsec", "dbd"])
    }

    /// US-19/D-03: every card from the `dbd` (Digital-by-Default Harms) deck
    /// must be a `.designHarm` — never `.technicalThreat`, regardless of
    /// curation state, since design-harm cards don't require curated severity
    /// at all.
    func testEveryDbdCardIsADesignHarm() throws {
        let loader = try makeLoader(bundle: .module)
        let dbd = DeckManifestEntry.all.first { $0.isDesignHarmDeck }!
        let seeds = try loader.loadDeck(dbd)
        XCTAssertGreaterThan(seeds.count, 0)
        XCTAssertTrue(seeds.allSatisfy(\.kind.isDesignHarm))
    }

    func testFaceCardsAreMarkedCritical() throws {
        let loader = try makeLoader(bundle: .module)
        let webapp = DeckManifestEntry.all.first { $0.edition == "webapp" }!
        let seeds = try loader.loadDeck(webapp)
        for seed in seeds where ["K", "Q", "A"].contains(seed.value) {
            XCTAssertTrue(seed.isCritical, "\(seed.cardId) (\(seed.value)) should be marked critical")
        }
        for seed in seeds where !["K", "Q", "A"].contains(seed.value) {
            XCTAssertFalse(seed.isCritical, "\(seed.cardId) (\(seed.value)) should not be marked critical")
        }
    }

    // MARK: - Fixture-based negative cases

    func testThrowsWhenACuratedCardHasAnInvalidSeverityString() throws {
        let bundle = try TestSupport.makeFixtureBundle(files: [
            "Cornucopia/fixture-deck.yaml": """
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
            """,
            "Cornucopia/fixture.curation.json": """
            { "FX1": { "severity": "not-a-real-severity", "owasp_refs": [], "mitre_refs": [] } }
            """,
            "ref-allowlists.json": "{ \"owasp_refs\": [] }",
            "mitre-atlas-allowlist.json": "{ \"mitre_refs\": [] }"
        ])
        let loader = try makeLoader(bundle: bundle)
        let entry = DeckManifestEntry(yamlFileName: "fixture-deck", curationFileName: "fixture.curation", edition: "fixture", isDesignHarmDeck: false)

        XCTAssertThrowsError(try loader.loadDeck(entry)) { error in
            guard case CardDecodeError.missingCuratedSeverity(let cardId) = error else {
                return XCTFail("expected .missingCuratedSeverity, got \(error)")
            }
            XCTAssertEqual(cardId, "FX1")
        }
    }

    func testThrowsOnAnOrphanCurationEntry() throws {
        let bundle = try TestSupport.makeFixtureBundle(files: [
            "Cornucopia/fixture-deck.yaml": """
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
            """,
            "Cornucopia/fixture.curation.json": """
            {
              "FX1": { "severity": "high", "owasp_refs": [], "mitre_refs": [] },
              "FX_DOES_NOT_EXIST": { "severity": "low", "owasp_refs": [], "mitre_refs": [] }
            }
            """,
            "ref-allowlists.json": "{ \"owasp_refs\": [] }",
            "mitre-atlas-allowlist.json": "{ \"mitre_refs\": [] }"
        ])
        let loader = try makeLoader(bundle: bundle)
        let entry = DeckManifestEntry(yamlFileName: "fixture-deck", curationFileName: "fixture.curation", edition: "fixture", isDesignHarmDeck: false)

        XCTAssertThrowsError(try loader.loadDeck(entry)) { error in
            guard case CardDecodeError.orphanCurationEntry(let cardId, _) = error else {
                return XCTFail("expected .orphanCurationEntry, got \(error)")
            }
            XCTAssertEqual(cardId, "FX_DOES_NOT_EXIST")
        }
    }

    func testSkipsACardWithNoCurationEntryAtAllRatherThanThrowing() throws {
        let bundle = try TestSupport.makeFixtureBundle(files: [
            "Cornucopia/fixture-deck.yaml": """
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
            """,
            "Cornucopia/fixture.curation.json": """
            { "FX1": { "severity": "high", "owasp_refs": [], "mitre_refs": [] } }
            """,
            "ref-allowlists.json": "{ \"owasp_refs\": [] }",
            "mitre-atlas-allowlist.json": "{ \"mitre_refs\": [] }"
        ])
        let loader = try makeLoader(bundle: bundle)
        let entry = DeckManifestEntry(yamlFileName: "fixture-deck", curationFileName: "fixture.curation", edition: "fixture", isDesignHarmDeck: false)

        let seeds = try loader.loadDeck(entry)
        XCTAssertEqual(seeds.map(\.cardId), ["FX1"])
    }
}
