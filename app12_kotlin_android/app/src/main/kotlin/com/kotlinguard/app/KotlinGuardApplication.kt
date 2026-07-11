package com.kotlinguard.app

import android.app.Application
import com.kotlinguard.data.di.DataContainer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * The composition root — the Kotlin/Room analogue of app11's `@main
 * SwiftGuardApp` struct building a `ModelContainer` and running
 * `ContentSeeder` at launch. Seeding runs on a background dispatcher since
 * Room forbids DB access on the main thread by default, unlike SwiftData's
 * `@MainActor`-bound `ModelContext`.
 */
class KotlinGuardApplication : Application() {
    lateinit var dataContainer: DataContainer
        private set

    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    /** `MainActivity` awaits this before showing `RootScreen`, so no screen ever reads an unseeded DB. */
    lateinit var seedingJob: Job
        private set

    override fun onCreate() {
        super.onCreate()
        dataContainer = DataContainer(this)
        seedingJob = applicationScope.launch {
            dataContainer.contentSeeder.seedIfNeeded()
        }
    }
}
