import SwiftData
import XCTest
@testable import SwiftGuardData

/// FR-17.1-equivalent: plain `localizedStandardContains`, no FTS index built
/// yet (see `SwiftDataSearchRepository`'s own doc comment) — these tests
/// pin exactly that behavior against real seeded threats and cards.
final class SearchRepositoryTests: XCTestCase {
    @MainActor
    func testFindsAThreatByTitleSubstring() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataSearchRepository(modelContext: container.mainContext)
        let results = try repo.query("injection", locale: .english)
        XCTAssertTrue(results.contains { $0.kind == .threat && $0.code == "A03:2021" })
        XCTAssertTrue(results.contains { $0.kind == .threat && $0.code == "LLM01:2025" })
    }

    @MainActor
    func testFindsACardByDescriptionSubstring() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataSearchRepository(modelContext: container.mainContext)
        let results = try repo.query("computational", locale: .english)
        XCTAssertTrue(results.contains { $0.kind == .card && $0.code == "LLM2" })
    }

    @MainActor
    func testReturnsNoResultsForANonsenseQuery() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataSearchRepository(modelContext: container.mainContext)
        XCTAssertTrue(try repo.query("zzzznonexistentqueryzzzz", locale: .english).isEmpty)
    }
}
