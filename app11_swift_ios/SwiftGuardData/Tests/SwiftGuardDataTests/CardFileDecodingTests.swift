import XCTest
import Yams
@testable import SwiftGuardData

/// D-06: pins the exact behavior every raw Cornucopia YAML decoder must
/// have — reject any unrecognized key, at every nesting level (top-level,
/// suit, card) — the hand-written `DynamicKey`-container replacement for
/// `Codable`'s normally-lenient default.
final class CardFileDecodingTests: XCTestCase {
    private let validYAML = """
    meta:
      edition: "webapp"
      component: "cards"
      language: "en"
      version: "3.0"
    suits:
    -
      id: "VE"
      name: "DATA VALIDATION & ENCODING"
      cards:
      -
        id: "VE2"
        value: "2"
        url: "https://cornucopia.owasp.org/cards/VE2"
        desc: "Some threat description."
        misc: "A note."
    """

    func testDecodesAValidDeck() throws {
        let cardFile = try YAMLDecoder().decode(CardFile.self, from: validYAML)
        XCTAssertEqual(cardFile.meta.edition, "webapp")
        XCTAssertEqual(cardFile.suits.count, 1)
        XCTAssertEqual(cardFile.suits[0].cards?.count, 1)
        XCTAssertEqual(cardFile.suits[0].cards?[0].id, "VE2")
    }

    func testRejectsUnrecognizedTopLevelKey() {
        let yaml = validYAML + "\nextra_top_level_key: \"evil\"\n"
        // The underlying error is a `CardDecodeError.unrecognizedFields` thrown from
        // `CardFile.init(from:)`, but `YAMLDecoder` may re-wrap it in a
        // `Swift.DecodingError` on the way out — asserting only that decoding fails
        // (not the exact wrapper shape) keeps this test honest about what's actually
        // guaranteed vs. an implementation detail of `Yams`.
        XCTAssertThrowsError(try YAMLDecoder().decode(CardFile.self, from: yaml))
    }

    func testRejectsUnrecognizedSuitKey() {
        let yaml = """
        meta:
          edition: "webapp"
          component: "cards"
          language: "en"
          version: "3.0"
        suits:
        -
          id: "VE"
          name: "DATA VALIDATION & ENCODING"
          unexpected_suit_field: "evil"
          cards: []
        """
        XCTAssertThrowsError(try YAMLDecoder().decode(CardFile.self, from: yaml))
    }

    func testRejectsUnrecognizedCardKey() {
        let yaml = """
        meta:
          edition: "webapp"
          component: "cards"
          language: "en"
          version: "3.0"
        suits:
        -
          id: "VE"
          name: "DATA VALIDATION & ENCODING"
          cards:
          -
            id: "VE2"
            value: "2"
            desc: "desc"
            unexpected_card_field: "evil"
        """
        XCTAssertThrowsError(try YAMLDecoder().decode(CardFile.self, from: yaml))
    }

    /// The "Common"/metadata suit has `sentences` instead of `cards` — it
    /// carries no threat data and must decode successfully with `cards == nil`,
    /// not be treated as a decode error.
    func testMetadataSuitWithSentencesDecodesWithNilCards() throws {
        let yaml = """
        meta:
          edition: "webapp"
          component: "cards"
          language: "en"
          version: "3.0"
        suits:
        -
          id: "Common"
          name: "Common"
          sentences: ["Deck title blurb."]
        """
        let cardFile = try YAMLDecoder().decode(CardFile.self, from: yaml)
        XCTAssertNil(cardFile.suits[0].cards)
    }
}
