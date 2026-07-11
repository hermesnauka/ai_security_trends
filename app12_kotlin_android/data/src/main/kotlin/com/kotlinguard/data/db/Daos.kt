package com.kotlinguard.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.kotlinguard.data.model.BookmarkEntity
import com.kotlinguard.data.model.CodeSampleEntity
import com.kotlinguard.data.model.ContentHashEntity
import com.kotlinguard.data.model.CornucopiaCardEntity
import com.kotlinguard.data.model.CrossReferenceEntity
import com.kotlinguard.data.model.FrameworkEntity
import com.kotlinguard.data.model.MitigationEntity
import com.kotlinguard.data.model.ThreatEntity

@Dao
interface FrameworkDao {
    @Query("SELECT * FROM frameworks ORDER BY name ASC")
    suspend fun list(): List<FrameworkEntity>

    @Query("SELECT * FROM frameworks WHERE code = :code LIMIT 1")
    suspend fun byCode(code: String): FrameworkEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(framework: FrameworkEntity)
}

@Dao
interface ThreatDao {
    /**
     * D-04-equivalent: Room's KSP annotation processor parses this SQL
     * string at BUILD time and verifies it against the actual entity
     * schema — a column-name typo is a compile error, not a runtime one.
     * The `:param IS NULL OR column = :param` pattern is this project's
     * equivalent of app11's "`filter == nil || ...`" single-`#Predicate`
     * idiom, expressed as a real (but always-bound, never-interpolated) SQL
     * string instead. `stride`/`tags` are TEXT columns holding a
     * kotlinx.serialization JSON array (db/Converters.kt) — matching a
     * single element is a documented `LIKE '%"X"%'` substring check, less
     * type-safe than SwiftData's native `Array.contains` in app11's
     * equivalent query, since Room has no first-class array-column type.
     */
    @Query(
        """
        SELECT * FROM threats
        WHERE (:frameworkCode IS NULL OR frameworkCode = :frameworkCode)
          AND (:severity IS NULL OR severity = :severity)
          AND (:category IS NULL OR category = :category)
          AND (:stride IS NULL OR stride LIKE '%"' || :stride || '"%')
          AND (:tag IS NULL OR tags LIKE '%"' || :tag || '"%')
          AND (:query IS NULL OR title LIKE '%' || :query || '%' OR descriptionEn LIKE '%' || :query || '%')
        ORDER BY
          CASE severity WHEN 'CRITICAL' THEN 0 WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 3 ELSE 4 END,
          code ASC
        """
    )
    suspend fun list(
        frameworkCode: String?,
        severity: String?,
        category: String?,
        stride: String?,
        tag: String?,
        query: String?
    ): List<ThreatEntity>

    @Query("SELECT * FROM threats WHERE code = :code LIMIT 1")
    suspend fun byCode(code: String): ThreatEntity?

    @Query("SELECT * FROM cross_references WHERE sourceThreatCode = :sourceCode")
    suspend fun crossReferences(sourceCode: String): List<CrossReferenceEntity>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(threat: ThreatEntity)

    @Update
    suspend fun update(threat: ThreatEntity)

    @Query("SELECT COUNT(*) FROM threats WHERE frameworkCode = :frameworkCode")
    suspend fun countForFramework(frameworkCode: String): Int
}

@Dao
interface CardDao {
    @Query("SELECT * FROM cards WHERE suitCode = :suitCode ORDER BY value ASC")
    suspend fun bySuit(suitCode: String): List<CornucopiaCardEntity>

    @Query("SELECT * FROM cards WHERE edition = :edition ORDER BY suitCode ASC, value ASC")
    suspend fun byEdition(edition: String): List<CornucopiaCardEntity>

    @Query("SELECT * FROM cards WHERE cardId = :cardId LIMIT 1")
    suspend fun byCardId(cardId: String): CornucopiaCardEntity?

    @Query("SELECT DISTINCT suitCode FROM cards WHERE edition = :edition ORDER BY suitCode ASC")
    suspend fun suitsForEdition(edition: String): List<String>

    @Query("SELECT * FROM cards WHERE descriptionEn LIKE '%' || :query || '%' OR descriptionPl LIKE '%' || :query || '%'")
    suspend fun search(query: String): List<CornucopiaCardEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(card: CornucopiaCardEntity)
}

@Dao
interface MitigationDao {
    @Query("SELECT * FROM mitigations WHERE threatCode = :threatCode")
    suspend fun forThreat(threatCode: String): List<MitigationEntity>

    @Query("SELECT * FROM mitigations WHERE cardId = :cardId")
    suspend fun forCard(cardId: String): List<MitigationEntity>

    @Query("SELECT * FROM mitigations WHERE slug = :slug LIMIT 1")
    suspend fun bySlug(slug: String): MitigationEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(mitigation: MitigationEntity)
}

@Dao
interface CodeSampleDao {
    @Query("SELECT * FROM code_samples WHERE mitigationSlug = :slug ORDER BY language ASC, sampleType ASC")
    suspend fun forMitigation(slug: String): List<CodeSampleEntity>

    @Query("SELECT COUNT(*) FROM code_samples WHERE mitigationSlug = :slug AND language = :language AND sampleType = :sampleType")
    suspend fun countExisting(slug: String, language: String, sampleType: String): Int

    @Insert
    suspend fun insert(sample: CodeSampleEntity)
}

@Dao
interface CrossReferenceDao {
    @Query("SELECT COUNT(*) FROM cross_references WHERE sourceThreatCode = :source AND targetThreatCode = :target")
    suspend fun exists(source: String, target: String): Int

    @Insert
    suspend fun insert(crossReference: CrossReferenceEntity)
}

@Dao
interface ContentHashDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(hash: ContentHashEntity)

    @Query("SELECT * FROM content_hashes")
    suspend fun all(): List<ContentHashEntity>
}

@Dao
interface BookmarkDao {
    @Query("SELECT * FROM bookmarks ORDER BY createdAt DESC")
    suspend fun list(): List<BookmarkEntity>

    @Query("SELECT COUNT(*) FROM bookmarks WHERE threatOrCardCode = :code")
    suspend fun exists(code: String): Int

    @Insert
    suspend fun insert(bookmark: BookmarkEntity)

    @Query("DELETE FROM bookmarks WHERE threatOrCardCode = :code")
    suspend fun delete(code: String)
}
