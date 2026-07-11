package com.kotlinguard.data.repository

import com.kotlinguard.data.db.ThreatDao
import com.kotlinguard.data.model.CrossReferenceEntity
import com.kotlinguard.data.model.ThreatEntity

/**
 * D-04-equivalent note (see Daos.kt ThreatDao.list): every filter is a bound
 * SQL parameter verified at KSP build time against `ThreatEntity`'s actual
 * columns, Room's compile-time-checked-query answer to app11's single
 * `#Predicate`.
 */
class RoomThreatRepository(private val threatDao: ThreatDao) : ThreatRepository {
    override suspend fun list(filter: ThreatFilter): List<ThreatEntity> = threatDao.list(
        frameworkCode = filter.frameworkCode,
        severity = filter.severity?.name,
        category = filter.category,
        stride = filter.stride?.name,
        tag = filter.tag,
        query = filter.query
    )

    override suspend fun detail(code: String): ThreatEntity? = threatDao.byCode(code)

    override suspend fun crossReferences(sourceCode: String): List<CrossReferenceEntity> =
        threatDao.crossReferences(sourceCode)
}
