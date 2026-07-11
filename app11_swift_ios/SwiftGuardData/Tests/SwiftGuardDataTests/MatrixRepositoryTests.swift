import SwiftData
import XCTest
@testable import SwiftGuardData

final class MatrixRepositoryTests: XCTestCase {
    @MainActor
    private func makeRepository(_ container: ModelContainer) -> SwiftDataMatrixRepository {
        SwiftDataMatrixRepository(
            modelContext: container.mainContext,
            frameworkRepository: SwiftDataFrameworkRepository(modelContext: container.mainContext),
            cardRepository: SwiftDataCardRepository(modelContext: container.mainContext)
        )
    }

    /// The 3 curated `LLM` suit cards (LLM2/LLM3/LLM4) reference 3 of the 10
    /// seeded `OWASP_LLM` threats via their curated `owasp_refs` — every
    /// threat gets a row (even with zero matching cards), but only those 3
    /// have a non-empty `cardIds`.
    @MainActor
    func testLlmMatrixMapsCardsToTheThreatsTheyReference() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let matrix = try makeRepository(container).llmMatrix()

        XCTAssertEqual(matrix.rows.count, 10)
        let byCode = Dictionary(uniqueKeysWithValues: matrix.rows.map { ($0.threatCode, $0.cardIds) })
        XCTAssertEqual(byCode["LLM10:2025"], ["LLM2"])
        XCTAssertEqual(byCode["LLM09:2025"], ["LLM3"])
        XCTAssertEqual(Set(byCode["LLM07:2025"] ?? []), ["LLM4"])
        XCTAssertEqual(byCode["LLM01:2025"], [])
    }

    /// requirements.md DR-01.4: no OWASP Agentic AI Top 10 threats are seeded
    /// yet — this must report its own incompleteness (a non-nil `note`,
    /// empty `rows`), not silently pad in unrelated data.
    @MainActor
    func testAgenticMatrixReportsItsOwnIncompleteness() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let matrix = try makeRepository(container).agenticMatrix()
        XCTAssertTrue(matrix.rows.isEmpty)
        XCTAssertNotNil(matrix.note)
    }

    @MainActor
    func testStrideHeatmapCountsCardsPerCategory() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let heatmap = try makeRepository(container).strideHeatmap()
        XCTAssertEqual(heatmap.categoryCounts.keys.count, 6)
        XCTAssertTrue(heatmap.categoryCounts.values.allSatisfy { $0 >= 0 })
    }
}
