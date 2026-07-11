package com.kotlinguard.data.di

import android.content.Context
import androidx.room.Room
import com.kotlinguard.data.assets.AndroidAssetSource
import com.kotlinguard.data.db.KotlinGuardDatabase
import com.kotlinguard.data.integrity.IntegrityChecker
import com.kotlinguard.data.repository.BookmarkRepository
import com.kotlinguard.data.repository.CardRepository
import com.kotlinguard.data.repository.FrameworkRepository
import com.kotlinguard.data.repository.MatrixRepository
import com.kotlinguard.data.repository.MitigationRepository
import com.kotlinguard.data.repository.RoomBookmarkRepository
import com.kotlinguard.data.repository.RoomCardRepository
import com.kotlinguard.data.repository.RoomFrameworkRepository
import com.kotlinguard.data.repository.RoomMatrixRepository
import com.kotlinguard.data.repository.RoomMitigationRepository
import com.kotlinguard.data.repository.RoomSearchRepository
import com.kotlinguard.data.repository.RoomThreatRepository
import com.kotlinguard.data.repository.SearchRepository
import com.kotlinguard.data.repository.ThreatRepository
import com.kotlinguard.data.seeding.ContentSeeder

/**
 * The `:app` module's composition root (`KotlinGuardApplication`) builds one
 * of these and holds it for the app's lifetime — the Kotlin/Room analogue of
 * app11's `SwiftGuardApp.swift` `@main` struct building a `ModelContainer`.
 * There is no DI framework (Hilt/Koin) wired in; PLAN.md never asked for
 * one, and a single manual container is simpler for an app this size.
 */
class DataContainer(context: Context) {
    private val database: KotlinGuardDatabase = Room.databaseBuilder(
        context.applicationContext,
        KotlinGuardDatabase::class.java,
        "kotlinguard.db"
    ).build()

    private val assetSource = AndroidAssetSource(context.applicationContext)

    val frameworkRepository: FrameworkRepository = RoomFrameworkRepository(database.frameworkDao())
    val threatRepository: ThreatRepository = RoomThreatRepository(database.threatDao())
    val cardRepository: CardRepository = RoomCardRepository(database.cardDao())
    val mitigationRepository: MitigationRepository = RoomMitigationRepository(database.mitigationDao())
    val bookmarkRepository: BookmarkRepository = RoomBookmarkRepository(database.bookmarkDao())
    val searchRepository: SearchRepository = RoomSearchRepository(database.threatDao(), database.cardDao())
    val matrixRepository: MatrixRepository = RoomMatrixRepository(frameworkRepository, threatRepository, cardRepository)

    private val integrityChecker = IntegrityChecker(assetSource, database.contentHashDao())

    val contentSeeder = ContentSeeder(
        assetSource = assetSource,
        frameworkDao = database.frameworkDao(),
        threatDao = database.threatDao(),
        cardDao = database.cardDao(),
        mitigationDao = database.mitigationDao(),
        codeSampleDao = database.codeSampleDao(),
        crossReferenceDao = database.crossReferenceDao(),
        integrityChecker = integrityChecker
    )

    suspend fun codeSamplesFor(mitigationSlug: String) = database.codeSampleDao().forMitigation(mitigationSlug)
}
