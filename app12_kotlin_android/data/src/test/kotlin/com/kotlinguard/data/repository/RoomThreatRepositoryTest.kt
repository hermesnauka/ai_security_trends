package com.kotlinguard.data.repository

import com.kotlinguard.data.model.Severity
import com.kotlinguard.data.support.RoomTestSupport
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class RoomThreatRepositoryTest {
    @Test
    fun combinesFrameworkAndSeverityFilters() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomThreatRepository(db.threatDao())
        val result = repo.list(ThreatFilter(frameworkCode = "OWASP_LLM", severity = Severity.CRITICAL))
        assertTrue(result.all { it.frameworkCode == "OWASP_LLM" && it.severity == Severity.CRITICAL })
    }

    @Test
    fun filtersBySeverityAlone() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomThreatRepository(db.threatDao())
        val result = repo.list(ThreatFilter(severity = Severity.CRITICAL))
        assertFalse(result.isEmpty())
        assertTrue(result.all { it.severity == Severity.CRITICAL })
    }

    @Test
    fun filtersByFreeTextQueryAgainstTitle() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomThreatRepository(db.threatDao())
        val result = repo.list(ThreatFilter(query = "Injection"))
        assertFalse(result.isEmpty())
        assertTrue(result.all {
            it.title.contains("Injection", ignoreCase = true) || it.descriptionEn.contains("Injection", ignoreCase = true)
        })
    }

    @Test
    fun noFiltersReturnsEverySeededThreat() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomThreatRepository(db.threatDao())
        assertEquals(20, repo.list(ThreatFilter()).size)
    }

    @Test
    fun detailReturnsTheMatchingThreat() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomThreatRepository(db.threatDao())
        val threat = repo.detail("A01:2021")
        assertEquals("Broken Access Control", threat?.title)
    }
}
