import XCTest
@testable import SwiftGuardData

/// SR-07-equivalent: exercises `ReferenceValidator` against the REAL bundled
/// `ref-allowlists.json`/`mitre-atlas-allowlist.json` (via `Bundle.module`,
/// symlinked to the same files `SwiftGuardApp` ships — see `Package.swift`).
final class ReferenceValidatorTests: XCTestCase {
    func testAcceptsAKnownOwaspRef() throws {
        let validator = try ReferenceValidator(bundle: .module)
        XCTAssertNoThrow(try validator.assertOwaspRefsValid(["A03:2021"], cardId: "TEST"))
    }

    func testAcceptsAKnownMitreRef() throws {
        let validator = try ReferenceValidator(bundle: .module)
        XCTAssertNoThrow(try validator.assertMitreRefsValid(["AML.T0051"], cardId: "TEST"))
    }

    func testRejectsAnUnknownOwaspRef() throws {
        let validator = try ReferenceValidator(bundle: .module)
        XCTAssertThrowsError(try validator.assertOwaspRefsValid(["A99:2099"], cardId: "TEST")) { error in
            guard case CardDecodeError.unknownReference(let value, let field, let cardId) = error else {
                return XCTFail("expected .unknownReference, got \(error)")
            }
            XCTAssertEqual(value, "A99:2099")
            XCTAssertEqual(field, "owasp_refs")
            XCTAssertEqual(cardId, "TEST")
        }
    }

    func testRejectsAnUnknownMitreRef() throws {
        let validator = try ReferenceValidator(bundle: .module)
        XCTAssertThrowsError(try validator.assertMitreRefsValid(["AML.T9999"], cardId: "TEST"))
    }

    func testEmptyRefsListNeverThrows() throws {
        let validator = try ReferenceValidator(bundle: .module)
        XCTAssertNoThrow(try validator.assertOwaspRefsValid([], cardId: "TEST"))
        XCTAssertNoThrow(try validator.assertMitreRefsValid([], cardId: "TEST"))
    }
}
