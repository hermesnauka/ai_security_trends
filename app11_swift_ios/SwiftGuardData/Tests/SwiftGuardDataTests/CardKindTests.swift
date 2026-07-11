import XCTest
@testable import SwiftGuardData

/// D-03: exercises the exhaustive-`switch` guarantee at the value level —
/// the compiler already guarantees no third case can exist; these tests
/// pin down the two cases' actual runtime behavior.
final class CardKindTests: XCTestCase {
    func testTechnicalThreatExposesItsSeverity() {
        let kind = CardKind.technicalThreat(severity: .critical)
        XCTAssertEqual(kind.severity, .critical)
        XCTAssertFalse(kind.isDesignHarm)
    }

    func testDesignHarmHasNoSeverity() {
        let kind = CardKind.designHarm
        XCTAssertNil(kind.severity)
        XCTAssertTrue(kind.isDesignHarm)
    }

    func testCodableRoundTrip() throws {
        let original = CardKind.technicalThreat(severity: .high)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CardKind.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testDesignHarmCodableRoundTrip() throws {
        let data = try JSONEncoder().encode(CardKind.designHarm)
        let decoded = try JSONDecoder().decode(CardKind.self, from: data)
        XCTAssertEqual(decoded, .designHarm)
    }
}
