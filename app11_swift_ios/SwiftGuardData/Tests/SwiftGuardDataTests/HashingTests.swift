import XCTest
@testable import SwiftGuardData

/// NIST/well-known SHA-256 test vectors — pins `Hashing` against known-correct
/// output rather than only checking internal consistency (e.g. "hashing twice
/// gives the same result" would pass even for a broken/non-SHA-256 digest).
final class HashingTests: XCTestCase {
    func testEmptyStringVector() {
        XCTAssertEqual(
            Hashing.sha256Hex(""),
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
    }

    func testAbcVector() {
        XCTAssertEqual(
            Hashing.sha256Hex("abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    func testIsDeterministic() {
        XCTAssertEqual(Hashing.sha256Hex("VE3|3|url|desc|misc"), Hashing.sha256Hex("VE3|3|url|desc|misc"))
    }

    func testDifferentInputsProduceDifferentHashes() {
        XCTAssertNotEqual(Hashing.sha256Hex("VE3"), Hashing.sha256Hex("VE4"))
    }
}
