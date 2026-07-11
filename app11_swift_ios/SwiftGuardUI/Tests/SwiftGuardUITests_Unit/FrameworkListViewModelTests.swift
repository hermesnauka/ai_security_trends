import SwiftData
import XCTest
@testable import SwiftGuardData
@testable import SwiftGuardUI

final class FrameworkListViewModelTests: XCTestCase {
    @MainActor
    func testLoadPopulatesFrameworksFromTheRepository() throws {
        let container = try UITestSupport.inMemoryContainer()
        UITestSupport.insertSampleData(into: container.mainContext)

        let viewModel = FrameworkListViewModel(modelContext: container.mainContext)
        viewModel.load()

        XCTAssertEqual(Set(viewModel.frameworks.map(\.code)), ["OWASP_LLM", "OWASP_WEB"])
        XCTAssertNil(viewModel.errorMessage)
    }
}
