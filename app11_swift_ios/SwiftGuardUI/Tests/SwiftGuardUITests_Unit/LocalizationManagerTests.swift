import XCTest
@testable import SwiftGuardData
@testable import SwiftGuardUI

/// D-05: `LocalizationManager` tracks only the in-app CONTENT locale — see
/// the scope note in the source file for what it deliberately does NOT do
/// (UI-chrome String Catalog swizzling).
final class LocalizationManagerTests: XCTestCase {
    @MainActor
    func testDefaultsToPolish() {
        let manager = LocalizationManager()
        XCTAssertEqual(manager.currentLocale, .polish)
    }

    @MainActor
    func testSetLocaleChangesTheCurrentLocale() {
        let manager = LocalizationManager()
        manager.setLocale(.english)
        XCTAssertEqual(manager.currentLocale, .english)
    }

    @MainActor
    func testSetLocaleFromRawValueAcceptsKnownCodes() {
        let manager = LocalizationManager(initialLocale: .polish)
        manager.setLocale(fromRawValue: "en")
        XCTAssertEqual(manager.currentLocale, .english)
    }

    /// SR-13.1-equivalent: an unrecognized raw value (e.g. a malformed
    /// deep-link parameter) must fall back to the CURRENT locale, not crash
    /// or silently switch to some default.
    @MainActor
    func testSetLocaleFromRawValueIgnoresUnknownCodes() {
        let manager = LocalizationManager(initialLocale: .english)
        manager.setLocale(fromRawValue: "fr")
        XCTAssertEqual(manager.currentLocale, .english)
    }
}
