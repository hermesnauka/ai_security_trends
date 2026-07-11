import SwiftData
import XCTest
@testable import SwiftGuardData

final class MitigationRepositoryTests: XCTestCase {
    @MainActor
    func testForThreatReturnsItsMitigation() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataMitigationRepository(modelContext: container.mainContext)
        let mitigations = try repo.forThreat(code: "A03:2021")
        XCTAssertTrue(mitigations.contains { $0.slug == "sql-injection-prevention" })
    }

    @MainActor
    func testForThreatReturnsEmptyWhenNoneAreSeeded() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataMitigationRepository(modelContext: container.mainContext)
        XCTAssertEqual(try repo.forThreat(code: "LLM08:2025"), [])
    }

    @MainActor
    func testForCardReturnsTheOneRealMitigationLinkedToACard() throws {
        // Of the 5 real seeded mitigations, only "rate-limiting-unbounded-
        // consumption" links to a card (`cardId: "LLM2"`) rather than a
        // threat — every other one has `cardId: null`.
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataMitigationRepository(modelContext: container.mainContext)
        let mitigations = try repo.forCard(cardId: "LLM2")
        XCTAssertEqual(mitigations.map(\.slug), ["rate-limiting-unbounded-consumption"])
    }

    @MainActor
    func testForCardReturnsEmptyWhenNoCardMitigationIsSeeded() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataMitigationRepository(modelContext: container.mainContext)
        XCTAssertEqual(try repo.forCard(cardId: "LLM3"), [])
    }
}
