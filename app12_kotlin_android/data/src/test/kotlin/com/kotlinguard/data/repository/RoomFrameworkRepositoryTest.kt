package com.kotlinguard.data.repository

import com.kotlinguard.data.support.RoomTestSupport
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** From `../../../user_stories+tests.md`'s US-01 (via `app11_swift_ios`'s TDD example). */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class RoomFrameworkRepositoryTest {
    @Test
    fun listReturnsAtLeastTenSeededFrameworks() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomFrameworkRepository(db.frameworkDao())
        assertTrue(repo.list().size >= 10)
    }

    @Test
    fun detailReturnsTheMatchingFramework() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomFrameworkRepository(db.frameworkDao())
        val framework = repo.detail("OWASP_LLM")
        assertEquals("OWASP_LLM", framework?.code)
    }

    @Test
    fun detailReturnsNullForAnUnknownCode() = runBlocking {
        val db = RoomTestSupport.seededDatabase()
        val repo = RoomFrameworkRepository(db.frameworkDao())
        assertNull(repo.detail("DOES_NOT_EXIST"))
    }
}
