package com.kotlinguard.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.CreationExtras
import com.kotlinguard.data.di.DataContainer

/**
 * No DI framework (Hilt/Koin) is wired in — one manual factory dispatching
 * on the requested `ViewModel` class, mirroring `DataContainer`'s own
 * "simpler than a framework for an app this size" reasoning.
 */
class ViewModelFactory(private val dataContainer: DataContainer) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T = when (modelClass) {
        FrameworkListViewModel::class.java -> FrameworkListViewModel(dataContainer.frameworkRepository) as T
        ThreatBrowserViewModel::class.java -> ThreatBrowserViewModel(dataContainer.threatRepository) as T
        CardSuitViewModel::class.java -> CardSuitViewModel(dataContainer.cardRepository) as T
        SearchViewModel::class.java -> SearchViewModel(dataContainer.searchRepository) as T
        BookmarksViewModel::class.java -> BookmarksViewModel(dataContainer.bookmarkRepository) as T
        else -> throw IllegalArgumentException("Unknown ViewModel class: ${modelClass.name}")
    }
}

/**
 * `ThreatDetailViewModel` and `CardSuitViewModel` need a runtime argument
 * (the threat code / suit code), so they get their own tiny factories rather
 * than being listed in the switch above (`CreationExtras` plumbing for a
 * per-instance arg is more ceremony than it saves here).
 */
class ThreatDetailViewModelFactory(
    private val dataContainer: DataContainer,
    private val threatCode: String
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T =
        ThreatDetailViewModel(
            dataContainer.threatRepository,
            dataContainer.mitigationRepository,
            dataContainer.bookmarkRepository,
            dataContainer.codeSampleRepository,
            threatCode
        ) as T
}
