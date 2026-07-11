import SwiftData
import XCTest
@testable import SwiftGuardData
@testable import SwiftGuardUI

final class ThreatBrowserViewModelTests: XCTestCase {
    @MainActor
    func testLoadWithNoFrameworkCodeReturnsEveryThreat() throws {
        let container = try UITestSupport.inMemoryContainer()
        UITestSupport.insertSampleData(into: container.mainContext)

        let viewModel = ThreatBrowserViewModel(modelContext: container.mainContext)
        viewModel.load()

        XCTAssertEqual(viewModel.threats.count, 3)
    }

    @MainActor
    func testInitialFrameworkCodeFiltersOnLoad() throws {
        let container = try UITestSupport.inMemoryContainer()
        UITestSupport.insertSampleData(into: container.mainContext)

        let viewModel = ThreatBrowserViewModel(modelContext: container.mainContext, frameworkCode: "OWASP_LLM")
        viewModel.load()

        XCTAssertEqual(Set(viewModel.threats.map(\.code)), ["LLM01:2025", "LLM02:2025"])
    }

    /// `severityChanged()` applies immediately (unlike `searchText`, which
    /// debounces via `didSet`) — no waiting required.
    @MainActor
    func testSeverityChangedAppliesImmediatelyWithNoDebounce() throws {
        let container = try UITestSupport.inMemoryContainer()
        UITestSupport.insertSampleData(into: container.mainContext)

        let viewModel = ThreatBrowserViewModel(modelContext: container.mainContext)
        viewModel.load()
        viewModel.selectedSeverity = .critical
        viewModel.severityChanged()

        XCTAssertEqual(Set(viewModel.threats.map(\.code)), ["LLM01:2025", "A01:2021"])
    }

    /// FR-02.4-equivalent: `searchText`'s debounce means the filter must NOT
    /// have applied the instant the property is set — only after ~300ms.
    @MainActor
    func testSearchTextDebouncesBeforeApplyingTheFilter() async throws {
        let container = try UITestSupport.inMemoryContainer()
        UITestSupport.insertSampleData(into: container.mainContext)

        let viewModel = ThreatBrowserViewModel(modelContext: container.mainContext)
        viewModel.load()
        XCTAssertEqual(viewModel.threats.count, 3)

        viewModel.searchText = "Prompt"
        XCTAssertEqual(viewModel.threats.count, 3, "filter must not have applied yet — it's debounced")

        try await Task.sleep(for: .milliseconds(450))
        XCTAssertEqual(viewModel.threats.map(\.code), ["LLM01:2025"])
    }
}
