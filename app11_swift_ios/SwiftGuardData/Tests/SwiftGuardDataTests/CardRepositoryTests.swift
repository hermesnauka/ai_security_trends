import SwiftData
import XCTest
@testable import SwiftGuardData

final class CardRepositoryTests: XCTestCase {
    @MainActor
    func testBySuitReturnsOnlyCuratedCardsInThatSuit() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataCardRepository(modelContext: container.mainContext)
        let cards = try repo.bySuit("LLM")
        XCTAssertEqual(Set(cards.map(\.cardId)), ["LLM2", "LLM3", "LLM4"])
        XCTAssertTrue(cards.allSatisfy { $0.suitCode == "LLM" })
    }

    @MainActor
    func testByEditionReturnsOnlyThatDeck() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataCardRepository(modelContext: container.mainContext)
        let cards = try repo.byEdition("dbd")
        XCTAssertFalse(cards.isEmpty)
        XCTAssertTrue(cards.allSatisfy { $0.edition == "dbd" && $0.kind.isDesignHarm })
    }

    @MainActor
    func testByCardIdReturnsNilForAnUnseededCard() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataCardRepository(modelContext: container.mainContext)
        XCTAssertNil(try repo.byCardId("DOES_NOT_EXIST"))
    }

    @MainActor
    func testSuitsForEditionReturnsDistinctSortedSuitCodes() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataCardRepository(modelContext: container.mainContext)
        let suits = try repo.suits(forEdition: "companion")
        XCTAssertEqual(suits, suits.sorted())
        XCTAssertEqual(suits, Array(Set(suits)))
    }
}
