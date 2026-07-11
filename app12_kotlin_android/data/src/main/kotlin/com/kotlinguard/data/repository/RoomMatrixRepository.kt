package com.kotlinguard.data.repository

import com.kotlinguard.data.model.StrideCategory
import com.kotlinguard.data.model.ThreatEntity

/**
 * PLAN.md §6 Phase 6 equivalent: `agenticMatrix()`'s honest-empty-state
 * behavior (no OWASP Agentic AI Top 10 threats are seeded, requirements.md
 * DR-01.4) and `mobileVsWebMatrix()`'s "juxtaposition, not a crosswalk"
 * framing both carry over unchanged from app09's Matrix_Service and app11's
 * SwiftDataMatrixRepository.
 */
class RoomMatrixRepository(
    private val frameworkRepository: FrameworkRepository,
    private val threatRepository: ThreatRepository,
    private val cardRepository: CardRepository
) : MatrixRepository {
    override suspend fun llmMatrix(): Matrix {
        val llmCards = cardRepository.bySuit("LLM")
        val llmThreats = threatsForFramework("OWASP_LLM")

        val rows = llmThreats.map { threat ->
            val matchingCardIds = llmCards.filter { threat.code in it.owaspRefs }.map { it.cardId }
            MatrixRow(threatCode = threat.code, threatTitle = threat.title, cardIds = matchingCardIds)
        }
        return Matrix(rows = rows, note = null)
    }

    override suspend fun agenticMatrix(): Matrix {
        val agenticThreats = threatsForFramework("OWASP_AGENTIC")
        val aaiCards = cardRepository.bySuit("AAI")

        val note = if (agenticThreats.isEmpty()) {
            "OWASP Agentic AI Top 10 threats are not yet seeded (requirements.md DR-01.4) — showing only the AAI suit cards."
        } else null

        val rows = if (agenticThreats.isEmpty()) {
            emptyList()
        } else {
            listOf(MatrixRow(threatCode = "", threatTitle = "", cardIds = aaiCards.map { it.cardId }))
        }
        return Matrix(rows = rows, note = note)
    }

    override suspend fun mobileVsWebMatrix(): Pair<Map<String, List<String>>, List<Pair<String, String>>> {
        val mobileCards = cardRepository.byEdition("mobileapp")
        val byCategory = mutableMapOf<String, MutableList<String>>()
        for (card in mobileCards) {
            for (ref in card.owaspRefs.filter { it.startsWith("MASVS-") }) {
                byCategory.getOrPut(ref) { mutableListOf() }.add(card.cardId)
            }
        }

        val webThreats = threatsForFramework("OWASP_WEB")
        val webTop10 = webThreats.map { it.code to it.title }

        return byCategory to webTop10
    }

    override suspend fun strideHeatmap(): StrideHeatmap {
        val suits = listOf(
            StrideCategory.S to "SP", StrideCategory.T to "TA", StrideCategory.R to "RE",
            StrideCategory.I to "ID", StrideCategory.D to "DS", StrideCategory.E to "EP"
        )
        val counts = suits.associate { (category, suitCode) -> category to cardRepository.bySuit(suitCode).size }
        return StrideHeatmap(categoryCounts = counts)
    }

    private suspend fun threatsForFramework(code: String): List<ThreatEntity> {
        frameworkRepository.detail(code) ?: return emptyList()
        return threatRepository.list(ThreatFilter(frameworkCode = code)).sortedBy { it.code }
    }
}
