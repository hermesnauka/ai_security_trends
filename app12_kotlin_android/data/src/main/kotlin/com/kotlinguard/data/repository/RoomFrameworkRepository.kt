package com.kotlinguard.data.repository

import com.kotlinguard.data.db.FrameworkDao
import com.kotlinguard.data.model.FrameworkEntity

class RoomFrameworkRepository(private val frameworkDao: FrameworkDao) : FrameworkRepository {
    override suspend fun list(): List<FrameworkEntity> = frameworkDao.list()
    override suspend fun detail(code: String): FrameworkEntity? = frameworkDao.byCode(code)
}
