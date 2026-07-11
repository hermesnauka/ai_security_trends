package com.kotlinguard.data.repository

import com.kotlinguard.data.support.RoomTestSupport
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class RoomMitigationRepositoryTest {
    @Test
    fun forThreatReturnsItsMitigation() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomMitigationRepository(db.mitigationDao())
        val mitigations = repo.forThreat("A03:2021")
        assertTrue(mitigations.any { it.slug == "sql-injection-prevention" })
    }

    @Test
    fun forThreatReturnsEmptyWhenNoneAreSeeded() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomMitigationRepository(db.mitigationDao())
        assertEquals(emptyList<Any>(), repo.forThreat("LLM08:2025"))
    }

    /**
     * Of the 5 real seeded mitigations, only "rate-limiting-unbounded-
     * consumption" links to a card (`cardId: "LLM2"`) rather than only a
     * threat.
     */
    @Test
    fun forCardReturnsTheOneRealMitigationLinkedToACard() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomMitigationRepository(db.mitigationDao())
        val mitigations = repo.forCard("LLM2")
        assertEquals(listOf("rate-limiting-unbounded-consumption"), mitigations.map { it.slug })
    }

    @Test
    fun forCardReturnsEmptyWhenNoCardMitigationIsSeeded() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomMitigationRepository(db.mitigationDao())
        assertEquals(emptyList<Any>(), repo.forCard("LLM3"))
    }
}
