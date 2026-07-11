package com.kotlinguard.data.repository

import com.kotlinguard.data.db.KotlinGuardDatabase
import com.kotlinguard.data.support.RoomTestSupport
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class RoomMatrixRepositoryTest {
    private fun makeRepository(db: KotlinGuardDatabase): RoomMatrixRepository {
        val frameworkRepository = RoomFrameworkRepository(db.frameworkDao())
        val threatRepository = RoomThreatRepository(db.threatDao())
        val cardRepository = RoomCardRepository(db.cardDao())
        return RoomMatrixRepository(frameworkRepository, threatRepository, cardRepository)
    }

    /**
     * The 3 curated `LLM` suit cards (LLM2/LLM3/LLM4) reference 3 of the 10
     * seeded `OWASP_LLM` threats via their curated `owasp_refs` — every
     * threat gets a row (even with zero matching cards), but only those 3
     * have a non-empty `cardIds`.
     */
    @Test
    fun llmMatrixMapsCardsToTheThreatsTheyReference() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val matrix = makeRepository(db).llmMatrix()

        assertEquals(10, matrix.rows.size)
        val byCode = matrix.rows.associate { it.threatCode to it.cardIds }
        assertEquals(listOf("LLM2"), byCode["LLM10:2025"])
        assertEquals(listOf("LLM3"), byCode["LLM09:2025"])
        assertEquals(setOf("LLM4"), byCode["LLM07:2025"]?.toSet())
        assertEquals(emptyList<String>(), byCode["LLM01:2025"])
    }

    /** No OWASP Agentic AI Top 10 threats are seeded yet — must report its own incompleteness. */
    @Test
    fun agenticMatrixReportsItsOwnIncompleteness() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val matrix = makeRepository(db).agenticMatrix()
        assertTrue(matrix.rows.isEmpty())
        assertNotNull(matrix.note)
    }

    @Test
    fun strideHeatmapCountsCardsPerCategory() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val heatmap = makeRepository(db).strideHeatmap()
        assertEquals(6, heatmap.categoryCounts.keys.size)
        assertTrue(heatmap.categoryCounts.values.all { it >= 0 })
    }
}
