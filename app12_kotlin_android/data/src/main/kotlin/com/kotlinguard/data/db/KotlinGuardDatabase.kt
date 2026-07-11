package com.kotlinguard.data.db

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.kotlinguard.data.model.BookmarkEntity
import com.kotlinguard.data.model.CodeSampleEntity
import com.kotlinguard.data.model.ContentHashEntity
import com.kotlinguard.data.model.CornucopiaCardEntity
import com.kotlinguard.data.model.CrossReferenceEntity
import com.kotlinguard.data.model.FrameworkEntity
import com.kotlinguard.data.model.MitigationEntity
import com.kotlinguard.data.model.ThreatEntity

@Database(
    entities = [
        FrameworkEntity::class,
        ThreatEntity::class,
        CornucopiaCardEntity::class,
        MitigationEntity::class,
        CodeSampleEntity::class,
        CrossReferenceEntity::class,
        ContentHashEntity::class,
        BookmarkEntity::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class KotlinGuardDatabase : RoomDatabase() {
    abstract fun frameworkDao(): FrameworkDao
    abstract fun threatDao(): ThreatDao
    abstract fun cardDao(): CardDao
    abstract fun mitigationDao(): MitigationDao
    abstract fun codeSampleDao(): CodeSampleDao
    abstract fun crossReferenceDao(): CrossReferenceDao
    abstract fun contentHashDao(): ContentHashDao
    abstract fun bookmarkDao(): BookmarkDao
}
