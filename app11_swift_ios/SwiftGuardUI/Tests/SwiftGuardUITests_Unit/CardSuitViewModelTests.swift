import SwiftData
import XCTest
@testable import SwiftGuardData
@testable import SwiftGuardUI

final class CardSuitViewModelTests: XCTestCase {
    @MainActor
    private func insertSampleCards(into context: ModelContext) {
        context.insert(CornucopiaCard(
            cardId: "LLM2", suitCode: "LLM", suitName: "Large Language Models", edition: "companion",
            value: "2", kind: .technicalThreat(severity: .high),
            descriptionEn: "LLM2 description.", descriptionPl: "",
            miscNote: nil, sourceUrl: nil, owaspRefs: ["LLM10:2025"], mitreRefs: [],
            contentSha256: "deadbeef", isCritical: false
        ))
        context.insert(CornucopiaCard(
            cardId: "SCO2", suitCode: "SCO", suitName: "Socioeconomic", edition: "dbd",
            value: "2", kind: .designHarm,
            descriptionEn: "SCO2 description.", descriptionPl: "",
            miscNote: nil, sourceUrl: nil, owaspRefs: [], mitreRefs: [],
            contentSha256: "cafebabe", isCritical: false
        ))
    }

    @MainActor
    func testLoadSuitReturnsOnlyThatSuitsCards() throws {
        let container = try UITestSupport.inMemoryContainer()
        insertSampleCards(into: container.mainContext)

        let viewModel = CardSuitViewModel(modelContext: container.mainContext)
        viewModel.loadSuit("LLM")

        XCTAssertEqual(viewModel.cards.map(\.cardId), ["LLM2"])
    }

    @MainActor
    func testLoadEditionReturnsOnlyThatEditionsCards() throws {
        let container = try UITestSupport.inMemoryContainer()
        insertSampleCards(into: container.mainContext)

        let viewModel = CardSuitViewModel(modelContext: container.mainContext)
        viewModel.loadEdition("dbd")

        XCTAssertEqual(viewModel.cards.map(\.cardId), ["SCO2"])
        XCTAssertTrue(viewModel.cards.allSatisfy { $0.kind.isDesignHarm })
    }
}
