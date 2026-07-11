package com.kotlinguard.data.seeding

import com.kotlinguard.data.integrity.IntegrityChecker
import com.kotlinguard.data.support.FileAssetSource
import com.kotlinguard.data.support.RoomTestSupport
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Full pipeline, end to end, against the REAL bundled content — the Kotlin
 * analogue of app11_swift_ios's `ContentSeederTests`, exercising exactly
 * what `KotlinGuardApplication.onCreate()` does on first launch.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ContentSeederTest {
    @Test
    fun seedsRealisticCountsFromRealBundledContent() = runBlocking {
        val db = RoomTestSupport.seededDatabase()

        val frameworks = db.frameworkDao().list()
        val threats = db.threatDao().list(null, null, null, null, null, null)
        // No "list all" query exists on MitigationDao — fetched per-threat instead.
        val mitigations = threats.flatMap { db.mitigationDao().forThreat(it.code) }.distinctBy { it.slug }

        assertTrue(frameworks.size >= 10) // matches user_stories+tests.md US-01
        assertEquals(20, threats.size) // OWASP Web Top 10 + LLM Top 10, in full
        assertEquals(5, mitigations.size)
    }

    @Test
    fun polishTranslationOverridesTheDefaultDescription() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val threat = db.threatDao().byCode("A01:2021")!!

        assertFalse(threat.descriptionPl.isEmpty())
        assertNotEquals(threat.descriptionEn, threat.descriptionPl)
    }

    @Test
    fun everyMitigationHasAtLeastOneCodeSample() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val threats = db.threatDao().list(null, null, null, null, null, null)
        val mitigations = threats.flatMap { db.mitigationDao().forThreat(it.code) }.distinctBy { it.slug }

        for (mitigation in mitigations) {
            val samples = db.codeSampleDao().forMitigation(mitigation.slug)
            assertTrue("${mitigation.slug} has no code samples", samples.isNotEmpty())
        }
    }

    /** Idempotency: re-running the seeder (every app launch) must not duplicate rows. */
    @Test
    fun reSeedingDoesNotDuplicateRows() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        // seededDatabase() already ran seedIfNeeded() once; run it again explicitly.
        val assetSource = FileAssetSource.real
        val integrityChecker = IntegrityChecker(assetSource, db.contentHashDao())
        val seeder = ContentSeeder(
            assetSource = assetSource,
            frameworkDao = db.frameworkDao(),
            threatDao = db.threatDao(),
            cardDao = db.cardDao(),
            mitigationDao = db.mitigationDao(),
            codeSampleDao = db.codeSampleDao(),
            crossReferenceDao = db.crossReferenceDao(),
            integrityChecker = integrityChecker
        )
        seeder.seedIfNeeded()

        val threats = db.threatDao().list(null, null, null, null, null, null)
        assertEquals(20, threats.size)
        assertEquals(20, threats.map { it.code }.distinct().size) // no duplicate codes

        val frameworks = db.frameworkDao().list()
        assertEquals(frameworks.size, frameworks.map { it.code }.distinct().size)
    }

    @Test
    fun crossReferenceLinksTwoRealSeededThreats() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val refs = db.threatDao().crossReferences("A03:2021")
        assertTrue(refs.any { it.targetThreatCode == "LLM01:2025" })
    }
}
