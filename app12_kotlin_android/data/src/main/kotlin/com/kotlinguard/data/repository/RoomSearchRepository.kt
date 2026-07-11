package com.kotlinguard.data.repository

import com.kotlinguard.data.db.CardDao
import com.kotlinguard.data.db.ThreatDao
import com.kotlinguard.data.model.AppLocale

/**
 * FR-17.1-equivalent: this is a plain `LIKE '%text%'` scan, not SQLite FTS4/5
 * — PLAN.md §6 Phase 6 states a dedicated FTS virtual table would be added
 * if relevance needs improve, mirroring app11's SwiftData
 * `localizedStandardContains` note (also plain-CONTAINS, no on-device
 * search index built yet either).
 */
class RoomSearchRepository(
    private val threatDao: ThreatDao,
    private val cardDao: CardDao
) : SearchRepository {
    override suspend fun query(text: String, locale: AppLocale): List<SearchResult> {
        val threatResults = threatDao.list(
            frameworkCode = null, severity = null, category = null, stride = null, tag = null, query = text
        ).map { threat ->
            SearchResult(
                code = threat.code,
                title = threat.title,
                excerpt = excerpt(threat.localizedDescription(locale), text),
                kind = SearchResult.Kind.THREAT
            )
        }

        val cardResults = cardDao.search(text).map { card ->
            SearchResult(
                code = card.cardId,
                title = card.cardId,
                excerpt = excerpt(card.localizedDescription(locale), text),
                kind = SearchResult.Kind.CARD
            )
        }

        return threatResults + cardResults
    }

    private fun excerpt(text: String, term: String, contextChars: Int = 80): String {
        val index = text.indexOf(term, ignoreCase = true)
        if (index < 0) return text.take(contextChars * 2)
        val start = (index - contextChars).coerceAtLeast(0)
        val end = (index + term.length + contextChars).coerceAtMost(text.length)
        return text.substring(start, end)
    }
}
