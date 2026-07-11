import XCTest

/// US-03 — Szczegóły zagrożenia z mitigacjami i kodem (`../user_stories+tests.md`).
/// Adapted from that doc's illustrative "Konwencje testowe" example to match
/// the REAL view structure: there is no separate "Code" screen — code
/// samples render inline per mitigation via `CodeSamplePanelView`, gated by
/// a `.confirmationDialog` (D-08). See `US01FrameworksUITests.swift` for why
/// this can't be run yet (no `.xcodeproj`).
final class US03ThreatDetailUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// D-08: the attack-demo code body must not exist before confirming the
    /// dialog, and must exist after — `LLM01:2025`'s one real mitigation
    /// ("prompt-injection-defense") ships a Python attack-demo sample, the
    /// language `CodeSamplePanelView` defaults to.
    func testDoesNotShowAttackDemoCodeBeforeConfirmation() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["tab-threats"].tap()
        app.cells["threat-row-LLM01:2025"].tap()

        let revealButton = app.buttons["attack-demo-reveal-button"]
        XCTAssertTrue(revealButton.waitForExistence(timeout: 2))
        XCTAssertFalse(app.otherElements["attack-demo-code-body"].exists)

        revealButton.tap()
        app.buttons["attack-demo-confirm-button"].tap()

        XCTAssertTrue(app.otherElements["attack-demo-code-body"].waitForExistence(timeout: 2))
    }

    func testCancellingTheConfirmationDialogLeavesTheCodeHidden() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["tab-threats"].tap()
        app.cells["threat-row-LLM01:2025"].tap()
        app.buttons["attack-demo-reveal-button"].tap()
        app.buttons["Anuluj"].tap()

        XCTAssertFalse(app.otherElements["attack-demo-code-body"].exists)
    }
}
