package com.kotlinguard.data.seeding

import com.kotlinguard.data.model.CodeLanguage
import com.kotlinguard.data.model.SampleType
import com.kotlinguard.data.support.RoomTestSupport
import io.kotest.property.Arb
import io.kotest.property.arbitrary.of
import io.kotest.property.checkAll
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * PLAN.md §10: "completeness is verified by a property over the seeded
 * dataset, not a type-level guarantee — `List<CodeSampleEntity>` has no
 * non-empty/all-languages variant in the Kotlin standard library." Mirrors
 * app11_swift_ios's `SwiftCheck`-based `CodeSampleCompletenessPropertyTests`.
 *
 * `Arb.of(slugs)` samples (with repetition, across many trials) from the
 * REAL seeded mitigation slugs rather than generating arbitrary values from
 * scratch — used here as a plain library call inside an ordinary JUnit4
 * `@Test`, not via Kotest's own Spec/JUnit5 runner (avoids mixing two test
 * frameworks in one module; see `data/build.gradle.kts`).
 * `ContentSeederTest.everyMitigationHasAtLeastOneCodeSample` covers the same
 * dataset deterministically as a non-probabilistic backstop.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CodeSampleCompletenessPropertyTest {
    @Test
    fun everySeededMitigationHasAllFiveLanguages() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val threats = db.threatDao().list(null, null, null, null, null, null)
        val mitigations = threats.flatMap { db.mitigationDao().forThreat(it.code) }.distinctBy { it.slug }
        assertTrue(mitigations.isNotEmpty())
        val slugs = mitigations.map { it.slug }

        checkAll(Arb.of(slugs)) { slug ->
            val samples = db.codeSampleDao().forMitigation(slug)
            val languages = samples.map { it.language }.toSet()
            assertTrue("$slug is missing languages: ${CodeLanguage.entries.toSet() - languages}", languages == CodeLanguage.entries.toSet())
        }
    }

    @Test
    fun everySeededMitigationHasBothAnAttackDemoAndADefenseSamplePerLanguage() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val threats = db.threatDao().list(null, null, null, null, null, null)
        val mitigations = threats.flatMap { db.mitigationDao().forThreat(it.code) }.distinctBy { it.slug }
        val slugs = mitigations.map { it.slug }

        checkAll(Arb.of(slugs)) { slug ->
            val samples = db.codeSampleDao().forMitigation(slug)
            for (language in CodeLanguage.entries) {
                val forLanguage = samples.filter { it.language == language }
                assertTrue(
                    "$slug/$language missing attack-demo or defense sample",
                    forLanguage.any { it.sampleType == SampleType.ATTACK_DEMO } &&
                        forLanguage.any { it.sampleType == SampleType.DEFENSE }
                )
            }
        }
    }
}
