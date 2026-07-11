import SwiftData
import XCTest
@testable import SwiftGuardData

/// From `../../user_stories+tests.md` US-02's TDD example — adapted to the
/// actual model shape (`threat.framework?.code`, a real `@Relationship`,
/// rather than the doc's illustrative `threat.frameworkCode` string).
final class ThreatRepositoryTests: XCTestCase {
    @MainActor
    func testCombinesFrameworkAndSeverityFilters() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataThreatRepository(modelContext: container.mainContext)
        let result = try repo.list(filter: ThreatFilter(frameworkCode: "OWASP_LLM", severity: .critical))
        XCTAssertTrue(result.allSatisfy { $0.framework?.code == "OWASP_LLM" && $0.severity == .critical })
    }

    @MainActor
    func testFiltersBySeverityAlone() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataThreatRepository(modelContext: container.mainContext)
        let result = try repo.list(filter: ThreatFilter(severity: .critical))
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.severity == .critical })
    }

    @MainActor
    func testFiltersByFreeTextQueryAgainstTitle() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataThreatRepository(modelContext: container.mainContext)
        let result = try repo.list(filter: ThreatFilter(query: "Injection"))
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy {
            $0.title.localizedCaseInsensitiveContains("Injection") || $0.descriptionEn.localizedCaseInsensitiveContains("Injection")
        })
    }

    @MainActor
    func testNoFiltersReturnsEverySeededThreat() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataThreatRepository(modelContext: container.mainContext)
        XCTAssertEqual(try repo.list(filter: ThreatFilter()).count, 20)
    }

    @MainActor
    func testDetailReturnsTheMatchingThreat() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataThreatRepository(modelContext: container.mainContext)
        let threat = try XCTUnwrap(try repo.detail(code: "A01:2021"))
        XCTAssertEqual(threat.title, "Broken Access Control")
    }
}
