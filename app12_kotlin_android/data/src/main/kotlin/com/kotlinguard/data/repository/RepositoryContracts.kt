package com.kotlinguard.data.repository

import com.kotlinguard.data.model.BookmarkEntity
import com.kotlinguard.data.model.CornucopiaCardEntity
import com.kotlinguard.data.model.CrossReferenceEntity
import com.kotlinguard.data.model.FrameworkEntity
import com.kotlinguard.data.model.MitigationEntity
import com.kotlinguard.data.model.Severity
import com.kotlinguard.data.model.StrideCategory
import com.kotlinguard.data.model.ThreatEntity

data class ThreatFilter(
    val frameworkCode: String? = null,
    val severity: Severity? = null,
    val stride: StrideCategory? = null,
    val category: String? = null,
    val tag: String? = null,
    val query: String? = null
)

data class SearchResult(
    val code: String,
    val title: String,
    val excerpt: String,
    val kind: Kind
) {
    enum class Kind { THREAT, CARD }
}

data class MatrixRow(
    val threatCode: String,
    val threatTitle: String,
    val cardIds: List<String>
)

data class Matrix(
    val rows: List<MatrixRow>,
    val note: String?
)

data class StrideHeatmap(
    val categoryCounts: Map<StrideCategory, Int>
)

interface FrameworkRepository {
    suspend fun list(): List<FrameworkEntity>
    suspend fun detail(code: String): FrameworkEntity?
}

interface ThreatRepository {
    suspend fun list(filter: ThreatFilter): List<ThreatEntity>
    suspend fun detail(code: String): ThreatEntity?
    suspend fun crossReferences(sourceCode: String): List<CrossReferenceEntity>
}

interface CardRepository {
    suspend fun bySuit(suitCode: String): List<CornucopiaCardEntity>
    suspend fun byEdition(edition: String): List<CornucopiaCardEntity>
    suspend fun byCardId(cardId: String): CornucopiaCardEntity?
    suspend fun suits(edition: String): List<String>
    // Digital-by-Default Harms (US-19): callers read severity only via
    // `card.kind.severityOrNull()`, the exhaustive `when` in CardKind.kt —
    // there is no separate "severity" accessor that could accidentally be
    // called on a design-harm card.
}

interface MitigationRepository {
    suspend fun forThreat(code: String): List<MitigationEntity>
    suspend fun forCard(cardId: String): List<MitigationEntity>
}

interface MatrixRepository {
    suspend fun llmMatrix(): Matrix
    suspend fun agenticMatrix(): Matrix
    suspend fun mobileVsWebMatrix(): Pair<Map<String, List<String>>, List<Pair<String, String>>>
    suspend fun strideHeatmap(): StrideHeatmap
}

interface SearchRepository {
    suspend fun query(text: String, locale: com.kotlinguard.data.model.AppLocale): List<SearchResult>
}

interface BookmarkRepository {
    suspend fun add(code: String): Unit
    suspend fun remove(code: String): Unit
    suspend fun list(): List<BookmarkEntity>
    // (Optional) sync via a future SyncCoordinator, the only type that would
    // import a cloud-sync SDK (D-07) — not built, same as app11.
}
