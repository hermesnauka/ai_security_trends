package com.kotlinguard.data.repository

import com.kotlinguard.data.db.CodeSampleDao
import com.kotlinguard.data.model.CodeSampleEntity

class RoomCodeSampleRepository(private val codeSampleDao: CodeSampleDao) : CodeSampleRepository {
    override suspend fun forMitigation(slug: String): List<CodeSampleEntity> = codeSampleDao.forMitigation(slug)
}
