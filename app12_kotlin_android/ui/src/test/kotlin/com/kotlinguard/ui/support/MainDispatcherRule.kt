package com.kotlinguard.ui.support

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.test.TestDispatcher
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import org.junit.rules.TestWatcher
import org.junit.runner.Description

/**
 * `viewModelScope` dispatches onto `Dispatchers.Main` by default, which has
 * no real implementation on a plain JVM (no Android runtime/Robolectric in
 * this test source set at all — see `FakeRepositories.kt`'s doc comment).
 * This rule installs a `TestDispatcher` as Main for the duration of each
 * test; pass `testDispatcher` to `runTest(...)` in the test body so the
 * ViewModel's coroutines and the test's virtual clock share one scheduler
 * (needed for `advanceTimeBy` to actually affect `viewModelScope.launch`
 * work — see `ThreatBrowserViewModelTest`'s debounce test).
 */
class MainDispatcherRule(
    val testDispatcher: TestDispatcher = UnconfinedTestDispatcher()
) : TestWatcher() {
    override fun starting(description: Description) {
        Dispatchers.setMain(testDispatcher)
    }

    override fun finished(description: Description) {
        Dispatchers.resetMain()
    }
}
