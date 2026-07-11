package com.kotlinguard.ui.support

import com.kotlinguard.data.model.AppLocale
import com.kotlinguard.data.model.BookmarkEntity
import com.kotlinguard.data.model.CodeSampleEntity
import com.kotlinguard.data.model.CornucopiaCardEntity
import com.kotlinguard.data.model.CrossReferenceEntity
import com.kotlinguard.data.model.FrameworkEntity
import com.kotlinguard.data.model.MitigationEntity
import com.kotlinguard.data.model.ThreatEntity
import com.kotlinguard.data.repository.BookmarkRepository
import com.kotlinguard.data.repository.CardRepository
import com.kotlinguard.data.repository.CodeSampleRepository
import com.kotlinguard.data.repository.FrameworkRepository
import com.kotlinguard.data.repository.MitigationRepository
import com.kotlinguard.data.repository.SearchRepository
import com.kotlinguard.data.repository.SearchResult
import com.kotlinguard.data.repository.ThreatFilter
import com.kotlinguard.data.repository.ThreatRepository

/**
 * ViewModels depend only on Repository INTERFACES (`:data`'s
 * `RepositoryContracts.kt`) — unlike `:data`'s own test suite (which needs
 * Robolectric for real Room execution), these fakes let ViewModel logic
 * (loading, filtering, debounce, bookmarking) be tested with zero Android
 * dependency at all, matching app11_swift_ios's small hand-inserted
 * in-memory `UITestSupport` dataset in spirit, adapted to plain Kotlin
 * collections instead of a real (if tiny) persistence layer.
 */
object SampleData {
    val llmFramework = FrameworkEntity("OWASP_LLM", "OWASP LLM Top 10", "2025", "", "")
    val webFramework = FrameworkEntity("OWASP_WEB", "OWASP Web Top 10", "2021", "", "")

    val promptInjection = ThreatEntity(
        code = "LLM01:2025", frameworkCode = "OWASP_LLM", title = "Prompt Injection",
        severity = com.kotlinguard.data.model.Severity.CRITICAL, category = "Injection",
        descriptionEn = "Prompt injection description.", descriptionPl = "",
        attackVector = "", attackSurface = "", stride = emptyList(), tags = emptyList()
    )
    val sensitiveDisclosure = ThreatEntity(
        code = "LLM02:2025", frameworkCode = "OWASP_LLM", title = "Sensitive Information Disclosure",
        severity = com.kotlinguard.data.model.Severity.HIGH, category = "Disclosure",
        descriptionEn = "Disclosure description.", descriptionPl = "",
        attackVector = "", attackSurface = "", stride = emptyList(), tags = emptyList()
    )
    val brokenAccessControl = ThreatEntity(
        code = "A01:2021", frameworkCode = "OWASP_WEB", title = "Broken Access Control",
        severity = com.kotlinguard.data.model.Severity.CRITICAL, category = "Access Control",
        descriptionEn = "Access control description.", descriptionPl = "",
        attackVector = "", attackSurface = "", stride = emptyList(), tags = emptyList()
    )

    val frameworks = listOf(llmFramework, webFramework)
    val threats = listOf(promptInjection, sensitiveDisclosure, brokenAccessControl)
}

class FakeFrameworkRepository(private val frameworks: List<FrameworkEntity> = SampleData.frameworks) : FrameworkRepository {
    override suspend fun list(): List<FrameworkEntity> = frameworks
    override suspend fun detail(code: String): FrameworkEntity? = frameworks.find { it.code == code }
}

class FakeThreatRepository(
    private val threats: List<ThreatEntity> = SampleData.threats,
    private val crossReferencesByCode: Map<String, List<CrossReferenceEntity>> = emptyMap()
) : ThreatRepository {
    override suspend fun list(filter: ThreatFilter): List<ThreatEntity> = threats.filter { threat ->
        (filter.frameworkCode == null || threat.frameworkCode == filter.frameworkCode) &&
            (filter.severity == null || threat.severity == filter.severity) &&
            (filter.category == null || threat.category == filter.category) &&
            (filter.query == null || threat.title.contains(filter.query, ignoreCase = true) ||
                threat.descriptionEn.contains(filter.query, ignoreCase = true))
    }

    override suspend fun detail(code: String): ThreatEntity? = threats.find { it.code == code }

    override suspend fun crossReferences(sourceCode: String): List<CrossReferenceEntity> =
        crossReferencesByCode[sourceCode] ?: emptyList()
}

class FakeMitigationRepository(
    private val byThreatCode: Map<String, List<MitigationEntity>> = emptyMap(),
    private val byCardId: Map<String, List<MitigationEntity>> = emptyMap()
) : MitigationRepository {
    override suspend fun forThreat(code: String): List<MitigationEntity> = byThreatCode[code] ?: emptyList()
    override suspend fun forCard(cardId: String): List<MitigationEntity> = byCardId[cardId] ?: emptyList()
}

class FakeCodeSampleRepository(private val byMitigationSlug: Map<String, List<CodeSampleEntity>> = emptyMap()) :
    CodeSampleRepository {
    override suspend fun forMitigation(slug: String): List<CodeSampleEntity> = byMitigationSlug[slug] ?: emptyList()
}

class FakeBookmarkRepository : BookmarkRepository {
    private val bookmarks = mutableListOf<BookmarkEntity>()

    override suspend fun add(code: String) {
        if (bookmarks.any { it.threatOrCardCode == code }) return
        bookmarks.add(BookmarkEntity(threatOrCardCode = code, createdAt = bookmarks.size.toLong()))
    }

    override suspend fun remove(code: String) {
        bookmarks.removeAll { it.threatOrCardCode == code }
    }

    override suspend fun list(): List<BookmarkEntity> = bookmarks.sortedByDescending { it.createdAt }
}

class FakeCardRepository(private val cards: List<CornucopiaCardEntity> = emptyList()) : CardRepository {
    override suspend fun bySuit(suitCode: String): List<CornucopiaCardEntity> = cards.filter { it.suitCode == suitCode }
    override suspend fun byEdition(edition: String): List<CornucopiaCardEntity> = cards.filter { it.edition == edition }
    override suspend fun byCardId(cardId: String): CornucopiaCardEntity? = cards.find { it.cardId == cardId }
    override suspend fun suits(edition: String): List<String> = cards.filter { it.edition == edition }.map { it.suitCode }.distinct().sorted()
}

class FakeSearchRepository(private val results: List<SearchResult> = emptyList()) : SearchRepository {
    override suspend fun query(text: String, locale: AppLocale): List<SearchResult> =
        results.filter { it.title.contains(text, ignoreCase = true) || it.excerpt.contains(text, ignoreCase = true) }
}
