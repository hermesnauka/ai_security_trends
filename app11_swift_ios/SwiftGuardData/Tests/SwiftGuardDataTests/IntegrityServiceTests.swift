import XCTest
import SwiftData
@testable import SwiftGuardData

final class IntegrityServiceTests: XCTestCase {
    @MainActor
    func testRealBundledHashesAllVerifyAsValid() throws {
        let container = try TestSupport.inMemoryContainer(seeded: false)
        let service = IntegrityService(bundle: .module)
        let results = try service.verify(modelContext: container.mainContext)

        XCTAssertEqual(results.count, 6) // one hash per Cornucopia deck
        XCTAssertTrue(results.values.allSatisfy { $0 })
        XCTAssertTrue(try service.allValid(modelContext: container.mainContext))
    }

    @MainActor
    func testDetectsATamperedFile() throws {
        let bundle = try TestSupport.makeFixtureBundle(files: [
            "hashes.json": """
            { "fixture-deck.yaml": "0000000000000000000000000000000000000000000000000000000000000000" }
            """,
            "Cornucopia/fixture-deck.yaml": "meta:\n  edition: fixture\nsuits: []\n"
        ])
        let service = IntegrityService(bundle: bundle)
        let container = try TestSupport.inMemoryContainer(seeded: false)
        let results = try service.verify(modelContext: container.mainContext)

        XCTAssertEqual(results["fixture-deck.yaml"], false)
        XCTAssertFalse(try service.allValid(modelContext: container.mainContext))
    }

    /// `fileName` is `.unique` — calling `verify()` twice (e.g. from a future
    /// periodic re-verification task) must update the existing `ContentHash`
    /// row, not violate the uniqueness constraint by inserting a duplicate.
    @MainActor
    func testCallingVerifyTwiceDoesNotDuplicateRows() throws {
        let container = try TestSupport.inMemoryContainer(seeded: false)
        let service = IntegrityService(bundle: .module)
        _ = try service.verify(modelContext: container.mainContext)
        _ = try service.verify(modelContext: container.mainContext)

        let descriptor = FetchDescriptor<ContentHash>()
        let rows = try container.mainContext.fetch(descriptor)
        XCTAssertEqual(rows.count, 6)
    }
}
