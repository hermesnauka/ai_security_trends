package com.kotlinguard.data.repository

import com.kotlinguard.data.db.BookmarkDao
import com.kotlinguard.data.model.BookmarkEntity

class RoomBookmarkRepository(private val bookmarkDao: BookmarkDao) : BookmarkRepository {
    override suspend fun add(code: String) {
        if (bookmarkDao.exists(code) > 0) return // already bookmarked, idempotent
        bookmarkDao.insert(BookmarkEntity(threatOrCardCode = code, createdAt = System.currentTimeMillis()))
    }

    override suspend fun remove(code: String) {
        bookmarkDao.delete(code)
    }

    override suspend fun list(): List<BookmarkEntity> = bookmarkDao.list()
}
