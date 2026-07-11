package com.kotlinguard.data.repository

import com.kotlinguard.data.db.CardDao
import com.kotlinguard.data.model.CornucopiaCardEntity

class RoomCardRepository(private val cardDao: CardDao) : CardRepository {
    override suspend fun bySuit(suitCode: String): List<CornucopiaCardEntity> = cardDao.bySuit(suitCode)
    override suspend fun byEdition(edition: String): List<CornucopiaCardEntity> = cardDao.byEdition(edition)
    override suspend fun byCardId(cardId: String): CornucopiaCardEntity? = cardDao.byCardId(cardId)
    override suspend fun suits(edition: String): List<String> = cardDao.suitsForEdition(edition)
}
