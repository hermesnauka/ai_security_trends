package com.kotlinguard.data.integrity

import com.kotlinguard.data.support.FileAssetSource
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
class IntegrityCheckerTest {
    @Test
    fun realBundledHashesAllVerifyAsValid() = runBlocking {
        val db = RoomTestSupport.inMemoryDatabase()
        val checker = IntegrityChecker(FileAssetSource.real, db.contentHashDao())
        val results = checker.verify()

        assertEquals(6, results.size) // one hash per Cornucopia deck
        assertTrue(results.values.all { it })
        assertTrue(checker.allValid())
    }

    @Test
    fun detectsATamperedFile() = runBlocking {
        val db = RoomTestSupport.inMemoryDatabase()
        val fixture = FileAssetSource.fixture(
            mapOf(
                "hashes.json" to """{ "fixture-deck.yaml": "0000000000000000000000000000000000000000000000000000000000000000" }""",
                "cornucopia/fixture-deck.yaml" to "meta:\n  edition: fixture\nsuits: []\n"
            )
        )
        val checker = IntegrityChecker(fixture, db.contentHashDao())
        val results = checker.verify()

        assertEquals(false, results["fixture-deck.yaml"])
        assertFalse(checker.allValid())
    }

    /** `fileName` is the primary key — calling `verify()` twice must update, not duplicate. */
    @Test
    fun callingVerifyTwiceDoesNotDuplicateRows() = runBlocking {
        val db = RoomTestSupport.inMemoryDatabase()
        val checker = IntegrityChecker(FileAssetSource.real, db.contentHashDao())
        checker.verify()
        checker.verify()

        assertEquals(6, db.contentHashDao().all().size)
    }
}
