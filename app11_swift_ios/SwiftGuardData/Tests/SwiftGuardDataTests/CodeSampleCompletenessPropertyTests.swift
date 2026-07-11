import SwiftCheck
import SwiftData
import XCTest
@testable import SwiftGuardData

/// PLAN.md §10: "completeness is verified by a SwiftCheck property over the
/// seeded dataset, not a type-level guarantee — `[CodeSample]` has no
/// non-empty/all-languages variant in the Swift standard library." Mirrors
/// `../../user_stories+tests.md` US-03's exact property.
///
/// `Gen.fromElements(of:)` samples (with repetition, across SwiftCheck's
/// default ~100 trials) from the REAL seeded `Mitigation` array rather than
/// generating arbitrary/random `Mitigation` values from scratch — the
/// meaningful "property" here is "true for every element of this real, small,
/// fixed set," which repeated sampling checks probabilistically.
/// `ContentSeederTests.testEveryMitigationHasAtLeastOneCodeSample` covers the
/// same dataset deterministically as a non-probabilistic backstop.
final class CodeSampleCompletenessPropertyTests: XCTestCase {
    @MainActor
    func testEverySeededMitigationHasAllFiveLanguages() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let mitigations = try container.mainContext.fetch(FetchDescriptor<Mitigation>())
        XCTAssertFalse(mitigations.isEmpty)

        let slugs = mitigations.map(\.slug)
        let codeSamplesBySlug = Dictionary(uniqueKeysWithValues: mitigations.map { ($0.slug, $0.codeSamples) })

        property("every seeded mitigation has all five languages") <- forAll(Gen<String>.fromElements(of: slugs)) { slug in
            let languages = Set((codeSamplesBySlug[slug] ?? []).map(\.language))
            return languages == Set(CodeLanguage.allCases)
        }
    }

    @MainActor
    func testEverySeededMitigationHasBothAnAttackDemoAndADefenseSamplePerLanguage() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let mitigations = try container.mainContext.fetch(FetchDescriptor<Mitigation>())
        let slugs = mitigations.map(\.slug)
        let codeSamplesBySlug = Dictionary(uniqueKeysWithValues: mitigations.map { ($0.slug, $0.codeSamples) })

        property("every language has both an attack-demo and a defense sample") <- forAll(Gen<String>.fromElements(of: slugs)) { slug in
            let samples = codeSamplesBySlug[slug] ?? []
            return CodeLanguage.allCases.allSatisfy { language in
                let forLanguage = samples.filter { $0.language == language }
                return forLanguage.contains { $0.sampleType == .attackDemo } && forLanguage.contains { $0.sampleType == .defense }
            }
        }
    }
}
