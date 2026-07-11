package com.kotlinguard.data.repository

import com.kotlinguard.data.model.BookmarkEntity
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
class RoomBookmarkRepositoryTest {
    @Test
    fun addIsIdempotent() = runBlocking {
        val db = RoomTestSupport.inMemoryDatabase()
        val repo = RoomBookmarkRepository(db.bookmarkDao())
        repo.add("A01:2021")
        repo.add("A01:2021")
        assertEquals(1, repo.list().size)
    }

    @Test
    fun removeDeletesTheBookmark() = runBlocking {
        val db = RoomTestSupport.inMemoryDatabase()
        val repo = RoomBookmarkRepository(db.bookmarkDao())
        repo.add("A01:2021")
        repo.remove("A01:2021")
        assertTrue(repo.list().isEmpty())
    }

    @Test
    fun removingANonExistentBookmarkDoesNotThrow() = runBlocking {
        val db = RoomTestSupport.inMemoryDatabase()
        val repo = RoomBookmarkRepository(db.bookmarkDao())
        repo.remove("DOES_NOT_EXIST") // must not throw
    }

    /**
     * Inserted directly via the DAO with explicit, distinct timestamps
     * rather than two back-to-back `add()` calls — `System.currentTimeMillis()`
     * has only 1ms resolution, so relying on real elapsed time between two
     * immediately-sequential calls would be a flaky test.
     */
    @Test
    fun listOrdersNewestFirst() = runBlocking {
        val db = RoomTestSupport.inMemoryDatabase()
        db.bookmarkDao().insert(BookmarkEntity(threatOrCardCode = "A01:2021", createdAt = 1000L))
        db.bookmarkDao().insert(BookmarkEntity(threatOrCardCode = "A03:2021", createdAt = 2000L))

        val repo = RoomBookmarkRepository(db.bookmarkDao())
        val list = repo.list()
        assertEquals(2, list.size)
        assertEquals("A03:2021", list.first().threatOrCardCode) // later createdAt, sorted newest-first
    }
}
