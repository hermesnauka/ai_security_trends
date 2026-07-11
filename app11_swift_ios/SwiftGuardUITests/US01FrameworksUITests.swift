import XCTest

/// US-01 — Katalog frameworków bezpieczeństwa (`../user_stories+tests.md`).
///
/// NOT RUNNABLE YET: this file lives in the `SwiftGuardUITests` target
/// PLAN.md §9 describes, but no `.xcodeproj` exists to actually build it as
/// an XCUITest bundle (see `../CLAUDE.md`) — someone needs to create the
/// Xcode project, add this directory as a UI test target against the real
/// `SwiftGuardApp`, before `xcodebuild test` can run this. The accessibility
/// identifiers referenced below (`tab-frameworks`, `framework-row-*`) are
/// real, already added to `RootView`/`FrameworkListView` in `SwiftGuardUI`
/// specifically so this test is genuinely correct against the shipped UI,
/// not just illustrative.
final class US01FrameworksUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTappingAFrameworkTileNavigatesToItsThreatList() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["tab-frameworks"].tap()
        let owaspLlmRow = app.cells["framework-row-OWASP_LLM"]
        XCTAssertTrue(owaspLlmRow.waitForExistence(timeout: 2))
        owaspLlmRow.tap()

        // Navigating a framework tile lands on `ThreatBrowserView` filtered
        // to that framework — `threat-row-LLM01:2025` is one of its 10 seeded
        // threats.
        XCTAssertTrue(app.cells["threat-row-LLM01:2025"].waitForExistence(timeout: 2))
    }

    func testAtLeastTenFrameworksAreListed() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["tab-frameworks"].tap()

        // Matches `FrameworkRepositoryTests.testList_ReturnsAtLeastTenSeededFrameworks`
        // (`SwiftGuardDataTests`) at the UI layer.
        XCTAssertTrue(app.cells["framework-row-OWASP_WEB"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.cells["framework-row-MITRE_ATLAS"].exists)
    }
}
