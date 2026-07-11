import XCTest
@testable import SwiftGuardData

/// `_comment` is a reserved top-level key holding a plain string, not a card
/// entry — these tests exercise `CurationFileLoader` directly against
/// temp-file JSON, with no `Bundle` involved at all.
final class CurationFileLoaderTests: XCTestCase {
    private func writeTempJSON(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("curation-\(UUID().uuidString).json")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testFiltersOutReservedCommentKey() throws {
        let url = try writeTempJSON("""
        {
          "_comment": "this is documentation, not a card entry",
          "VE3": { "severity": "critical", "owasp_refs": ["A03:2021"], "mitre_refs": [] }
        }
        """)
        let curation = try CurationFileLoader.load(from: url)
        XCTAssertNil(curation["_comment"])
        XCTAssertEqual(curation["VE3"]?.severity, "critical")
        XCTAssertEqual(curation["VE3"]?.owaspRefs, ["A03:2021"])
    }

    func testDefaultsMissingRefsToEmptyArrays() throws {
        let url = try writeTempJSON("""
        { "VE4": { "severity": "high" } }
        """)
        let curation = try CurationFileLoader.load(from: url)
        XCTAssertEqual(curation["VE4"]?.owaspRefs, [])
        XCTAssertEqual(curation["VE4"]?.mitreRefs, [])
    }

    func testLoadTranslationsFiltersCommentAndKeepsStrings() throws {
        let url = try writeTempJSON("""
        {
          "_comment": "Reviewed Polish translations, per card_id.",
          "VE2": "Opis karty po polsku."
        }
        """)
        let translations = try CurationFileLoader.loadTranslations(from: url)
        XCTAssertNil(translations["_comment"])
        XCTAssertEqual(translations["VE2"], "Opis karty po polsku.")
    }

    func testThrowsWhenRootIsNotAnObject() throws {
        let url = try writeTempJSON("[1, 2, 3]")
        XCTAssertThrowsError(try CurationFileLoader.load(from: url))
    }
}
