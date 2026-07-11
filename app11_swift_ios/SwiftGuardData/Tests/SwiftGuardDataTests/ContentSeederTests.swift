import XCTest
import SwiftData
@testable import SwiftGuardData

/// Full pipeline, end to end, against the REAL bundled content — this is
/// exactly what `SwiftGuardApp`'s `@main` composition root does on first
/// launch, exercised here without needing the app or a simulator at all.
final class ContentSeederTests: XCTestCase {
    @MainActor
    func testSeedsRealisticCountsFromRealBundledContent() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)

        let frameworks = try container.mainContext.fetch(FetchDescriptor<Framework>())
        let threats = try container.mainContext.fetch(FetchDescriptor<Threat>())
        let mitigations = try container.mainContext.fetch(FetchDescriptor<Mitigation>())
        let crossReferences = try container.mainContext.fetch(FetchDescriptor<CrossReference>())

        XCTAssertGreaterThanOrEqual(frameworks.count, 10) // matches user_stories+tests.md US-01
        XCTAssertEqual(threats.count, 20) // OWASP Web Top 10 + LLM Top 10, in full
        XCTAssertEqual(mitigations.count, 5)
        XCTAssertEqual(crossReferences.count, 4)
    }

    @MainActor
    func testPolishTranslationOverridesTheDefaultDescription() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        var descriptor = FetchDescriptor<Threat>(predicate: #Predicate { $0.code == "A01:2021" })
        descriptor.fetchLimit = 1
        let threat = try XCTUnwrap(try container.mainContext.fetch(descriptor).first)

        XCTAssertFalse(threat.descriptionPl.isEmpty)
        XCTAssertNotEqual(threat.descriptionPl, threat.descriptionEn)
        XCTAssertEqual(threat.localizedDescription(.polish), threat.descriptionPl)
        XCTAssertEqual(threat.localizedDescription(.english), threat.descriptionEn)
    }

    @MainActor
    func testEveryMitigationHasAtLeastOneCodeSample() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let mitigations = try container.mainContext.fetch(FetchDescriptor<Mitigation>())
        for mitigation in mitigations {
            XCTAssertFalse(mitigation.codeSamples.isEmpty, "\(mitigation.slug) has no code samples")
        }
    }

    /// Idempotency: re-running the seeder (e.g. on every app launch, per
    /// `ContentSeeder.seedIfNeeded`'s doc comment) must not duplicate rows.
    @MainActor
    func testReSeedingDoesNotDuplicateRows() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let seeder = ContentSeeder(bundle: .module, integrityService: IntegrityService(bundle: .module))
        try seeder.seedIfNeeded(modelContext: container.mainContext)
        try seeder.seedIfNeeded(modelContext: container.mainContext)

        let threats = try container.mainContext.fetch(FetchDescriptor<Threat>())
        let frameworks = try container.mainContext.fetch(FetchDescriptor<Framework>())
        let cards = try container.mainContext.fetch(FetchDescriptor<CornucopiaCard>())

        XCTAssertEqual(threats.count, 20)
        XCTAssertEqual(Set(threats.map(\.code)).count, 20) // no duplicate codes
        XCTAssertEqual(frameworks.count, Set(frameworks.map(\.code)).count)
        XCTAssertEqual(cards.count, Set(cards.map(\.cardId)).count)
    }

    @MainActor
    func testCrossReferenceLinksTwoRealSeededThreats() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repository = SwiftDataThreatRepository(modelContext: container.mainContext)
        let refs = try repository.crossReferences(sourceCode: "A03:2021")
        XCTAssertTrue(refs.contains { $0.targetThreatCode == "LLM01:2025" && $0.relationshipType == .related })
    }
}
