package com.kotlinguard.data.repository

import com.kotlinguard.data.db.MitigationDao
import com.kotlinguard.data.model.MitigationEntity

class RoomMitigationRepository(private val mitigationDao: MitigationDao) : MitigationRepository {
    override suspend fun forThreat(code: String): List<MitigationEntity> = mitigationDao.forThreat(code)
    override suspend fun forCard(cardId: String): List<MitigationEntity> = mitigationDao.forCard(cardId)
}
