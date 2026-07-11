import SwiftData
import XCTest
@testable import SwiftGuardData
@testable import SwiftGuardUI

final class ThreatDetailViewModelTests: XCTestCase {
    @MainActor
    func testLoadPopulatesTheMatchingThreat() throws {
        let container = try UITestSupport.inMemoryContainer()
        UITestSupport.insertSampleData(into: container.mainContext)

        let viewModel = ThreatDetailViewModel(modelContext: container.mainContext)
        viewModel.load(threatCode: "LLM01:2025")

        XCTAssertEqual(viewModel.threat?.title, "Prompt Injection")
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testLoadWithAnUnknownCodeLeavesThreatNil() throws {
        let container = try UITestSupport.inMemoryContainer()
        UITestSupport.insertSampleData(into: container.mainContext)

        let viewModel = ThreatDetailViewModel(modelContext: container.mainContext)
        viewModel.load(threatCode: "DOES_NOT_EXIST")

        XCTAssertNil(viewModel.threat)
    }
}
