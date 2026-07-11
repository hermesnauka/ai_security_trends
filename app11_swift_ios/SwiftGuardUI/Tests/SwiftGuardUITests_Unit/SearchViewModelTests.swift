import SwiftData
import XCTest
@testable import SwiftGuardData
@testable import SwiftGuardUI

final class SearchViewModelTests: XCTestCase {
    @MainActor
    func testEmptyQueryTextProducesNoResultsAndDoesNotHitTheRepository() throws {
        let container = try UITestSupport.inMemoryContainer()
        UITestSupport.insertSampleData(into: container.mainContext)
        let localizationManager = LocalizationManager()

        let viewModel = SearchViewModel(modelContext: container.mainContext, localizationManager: localizationManager)
        viewModel.queryText = "   "
        viewModel.search()

        XCTAssertTrue(viewModel.results.isEmpty)
    }

    @MainActor
    func testSearchFindsAMatchingThreatByTitle() throws {
        let container = try UITestSupport.inMemoryContainer()
        UITestSupport.insertSampleData(into: container.mainContext)
        let localizationManager = LocalizationManager()

        let viewModel = SearchViewModel(modelContext: container.mainContext, localizationManager: localizationManager)
        viewModel.queryText = "Prompt"
        viewModel.search()

        XCTAssertTrue(viewModel.results.contains { $0.code == "LLM01:2025" })
        XCTAssertNil(viewModel.errorMessage)
    }
}
