import Foundation
import SwiftData

/// PLAN.md §6 Phase 6 equivalent: /matrix/agentic's honest-empty-state
/// behavior (no OWASP Agentic AI Top 10 threats are seeded, requirements.md
/// DR-01.4) and /matrix/mobile-vs-web's "juxtaposition, not a crosswalk"
/// framing both carry over unchanged from app09's Matrix_Service.
@MainActor
public final class SwiftDataMatrixRepository: MatrixRepository {
    private let modelContext: ModelContext
    private let frameworkRepository: FrameworkRepository
    private let cardRepository: CardRepository

    public init(modelContext: ModelContext, frameworkRepository: FrameworkRepository, cardRepository: CardRepository) {
        self.modelContext = modelContext
        self.frameworkRepository = frameworkRepository
        self.cardRepository = cardRepository
    }

    public func llmMatrix() throws -> Matrix {
        let llmCards = try cardRepository.bySuit("LLM")
        let llmThreats = try threats(forFrameworkCode: "OWASP_LLM")

        let rows = llmThreats.map { threat -> MatrixRow in
            let matchingCardIds = llmCards
                .filter { $0.owaspRefs.contains(threat.code) }
                .map(\.cardId)
            return MatrixRow(threatCode: threat.code, threatTitle: threat.title, cardIds: matchingCardIds)
        }
        return Matrix(rows: rows, note: nil)
    }

    public func agenticMatrix() throws -> Matrix {
        let agenticThreats = try threats(forFrameworkCode: "OWASP_AGENTIC")
        let aaiCards = try cardRepository.bySuit("AAI")

        let note: String? = agenticThreats.isEmpty
            ? "OWASP Agentic AI Top 10 threats are not yet seeded (requirements.md DR-01.4) — showing only the AAI suit cards."
            : nil

        let rows = [MatrixRow(threatCode: "", threatTitle: "", cardIds: aaiCards.map(\.cardId))]
        return Matrix(rows: agenticThreats.isEmpty ? [] : rows, note: note)
    }

    public func mobileVsWebMatrix() throws -> (masvsCategories: [String: [String]], webTop10: [(code: String, title: String)]) {
        let mobileCards = try cardRepository.byEdition("mobileapp")
        var byCategory: [String: [String]] = [:]
        for card in mobileCards {
            for ref in card.owaspRefs where ref.hasPrefix("MASVS-") {
                byCategory[ref, default: []].append(card.cardId)
            }
        }

        let webThreats = try threats(forFrameworkCode: "OWASP_WEB")
        let webTop10 = webThreats.map { (code: $0.code, title: $0.title) }

        return (byCategory, webTop10)
    }

    public func strideHeatmap() throws -> StrideHeatmap {
        let suits: [(StrideCategory, String)] = [(.s, "SP"), (.t, "TA"), (.r, "RE"), (.i, "ID"), (.d, "DS"), (.e, "EP")]
        var counts: [StrideCategory: Int] = [:]
        for (category, suitCode) in suits {
            counts[category] = try cardRepository.bySuit(suitCode).count
        }
        return StrideHeatmap(categoryCounts: counts)
    }

    private func threats(forFrameworkCode code: String) throws -> [Threat] {
        guard let framework = try frameworkRepository.detail(code: code) else { return [] }
        return framework.threats.sorted { $0.code < $1.code }
    }
}
