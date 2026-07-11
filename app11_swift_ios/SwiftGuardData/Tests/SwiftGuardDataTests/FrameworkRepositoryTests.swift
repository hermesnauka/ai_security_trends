import SwiftData
import XCTest
@testable import SwiftGuardData

/// From `../../user_stories+tests.md` US-01's literal TDD example.
final class FrameworkRepositoryTests: XCTestCase {
    @MainActor
    func testList_ReturnsAtLeastTenSeededFrameworks() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataFrameworkRepository(modelContext: container.mainContext)
        XCTAssertGreaterThanOrEqual(try repo.list().count, 10)
    }

    @MainActor
    func testDetail_ReturnsTheMatchingFramework() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataFrameworkRepository(modelContext: container.mainContext)
        let framework = try XCTUnwrap(try repo.detail(code: "OWASP_LLM"))
        XCTAssertEqual(framework.code, "OWASP_LLM")
    }

    @MainActor
    func testDetail_ReturnsNilForAnUnknownCode() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataFrameworkRepository(modelContext: container.mainContext)
        XCTAssertNil(try repo.detail(code: "DOES_NOT_EXIST"))
    }
}
