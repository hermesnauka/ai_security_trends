package com.kotlinguard.data.repository

import com.kotlinguard.data.model.AppLocale
import com.kotlinguard.data.support.RoomTestSupport
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** FR-17.1-equivalent: plain `LIKE '%text%'`, no FTS index built yet. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class RoomSearchRepositoryTest {
    @Test
    fun findsAThreatByTitleSubstring() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomSearchRepository(db.threatDao(), db.cardDao())
        val results = repo.query("injection", AppLocale.ENGLISH)
        assertTrue(results.any { it.kind == SearchResult.Kind.THREAT && it.code == "A03:2021" })
        assertTrue(results.any { it.kind == SearchResult.Kind.THREAT && it.code == "LLM01:2025" })
    }

    @Test
    fun findsACardByDescriptionSubstring() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomSearchRepository(db.threatDao(), db.cardDao())
        val results = repo.query("computational", AppLocale.ENGLISH)
        assertTrue(results.any { it.kind == SearchResult.Kind.CARD && it.code == "LLM2" })
    }

    @Test
    fun returnsNoResultsForANonsenseQuery() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomSearchRepository(db.threatDao(), db.cardDao())
        assertTrue(repo.query("zzzznonexistentqueryzzzz", AppLocale.ENGLISH).isEmpty())
    }
}
