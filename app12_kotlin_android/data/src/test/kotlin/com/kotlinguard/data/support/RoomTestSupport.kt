package com.kotlinguard.data.support

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.kotlinguard.data.db.KotlinGuardDatabase
import com.kotlinguard.data.integrity.IntegrityChecker
import com.kotlinguard.data.seeding.ContentSeeder

/**
 * Room fundamentally needs an Android runtime (unlike SwiftData, a pure
 * Swift/Foundation library — app11_swift_ios's equivalent
 * `TestSupport.inMemoryContainer` runs under plain `swift test`, no
 * emulator). Every test file that uses this needs
 * `@RunWith(RobolectricTestRunner::class)` for `ApplicationProvider` to
 * resolve a Context at all.
 */
object RoomTestSupport {
    fun inMemoryDatabase(): KotlinGuardDatabase {
        val context = ApplicationProvider.getApplicationContext<Context>()
        return Room.inMemoryDatabaseBuilder(context, KotlinGuardDatabase::class.java)
            .allowMainThreadQueries() // test-only escape hatch — Robolectric runs everything on one thread
            .build()
    }

    /**
     * A `KotlinGuardDatabase` seeded from the REAL bundled content
     * (`FileAssetSource.real`) — the same "don't duplicate the real dataset"
     * principle as app11_swift_ios's resource-symlink trick, reached here
     * via a plain relative filesystem path instead.
     */
    suspend fun seededDatabase(): KotlinGuardDatabase {
        val db = inMemoryDatabase()
        val assetSource = FileAssetSource.real
        val integrityChecker = IntegrityChecker(assetSource, db.contentHashDao())
        val seeder = ContentSeeder(
            assetSource = assetSource,
            frameworkDao = db.frameworkDao(),
            threatDao = db.threatDao(),
            cardDao = db.cardDao(),
            mitigationDao = db.mitigationDao(),
            codeSampleDao = db.codeSampleDao(),
            crossReferenceDao = db.crossReferenceDao(),
            integrityChecker = integrityChecker
        )
        seeder.seedIfNeeded()
        return db
    }
}
