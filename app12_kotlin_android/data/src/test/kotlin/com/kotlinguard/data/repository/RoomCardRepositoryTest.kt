package com.kotlinguard.data.repository

import com.kotlinguard.data.support.RoomTestSupport
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class RoomCardRepositoryTest {
    @Test
    fun bySuitReturnsOnlyCuratedCardsInThatSuit() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomCardRepository(db.cardDao())
        val cards = repo.bySuit("LLM")
        assertEquals(setOf("LLM2", "LLM3", "LLM4"), cards.map { it.cardId }.toSet())
        assertTrue(cards.all { it.suitCode == "LLM" })
    }

    @Test
    fun byEditionReturnsOnlyThatDeck() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomCardRepository(db.cardDao())
        val cards = repo.byEdition("dbd")
        assertFalse(cards.isEmpty())
        assertTrue(cards.all { it.edition == "dbd" && it.kind.isDesignHarm })
    }

    @Test
    fun byCardIdReturnsNullForAnUnseededCard() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomCardRepository(db.cardDao())
        assertNull(repo.byCardId("DOES_NOT_EXIST"))
    }

    @Test
    fun suitsForEditionReturnsDistinctSortedSuitCodes() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomCardRepository(db.cardDao())
        val suits = repo.suits("companion")
        assertEquals(suits.sorted(), suits)
        assertEquals(suits.distinct(), suits)
    }
}
