package com.kotlinguard.ui.viewmodel

import com.kotlinguard.data.model.Severity
import com.kotlinguard.ui.support.FakeThreatRepository
import com.kotlinguard.ui.support.MainDispatcherRule
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class ThreatBrowserViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun loadWithNoFrameworkCodeReturnsEveryThreat() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = ThreatBrowserViewModel(FakeThreatRepository())
        viewModel.load()
        assertEquals(3, viewModel.threats.size)
    }

    @Test
    fun initialFrameworkCodeFiltersOnLoad() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = ThreatBrowserViewModel(FakeThreatRepository(), selectedFrameworkCode = "OWASP_LLM")
        viewModel.load()
        assertEquals(setOf("LLM01:2025", "LLM02:2025"), viewModel.threats.map { it.code }.toSet())
    }

    /** `severityChanged()` applies immediately — no debounce, unlike `searchText`. */
    @Test
    fun severityChangedAppliesImmediatelyWithNoDebounce() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = ThreatBrowserViewModel(FakeThreatRepository())
        viewModel.load()
        viewModel.severityChanged(Severity.CRITICAL)
        assertEquals(setOf("LLM01:2025", "A01:2021"), viewModel.threats.map { it.code }.toSet())
    }

    /**
     * FR-02.4-equivalent: the ~300ms debounce means the filter must NOT have
     * applied the instant `searchText` is set — only after virtual time
     * advances past it. Using `advanceTimeBy` (shared scheduler via
     * `MainDispatcherRule`) makes this deterministic and instant to run,
     * unlike app11_swift_ios's equivalent test, which does a real ~450ms
     * wall-clock `Task.sleep` since Swift's `Task.sleep` isn't virtual-time
     * controllable the way a `TestDispatcher` is.
     */
    @Test
    fun searchTextDebouncesBeforeApplyingTheFilter() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = ThreatBrowserViewModel(FakeThreatRepository())
        viewModel.load()
        assertEquals(3, viewModel.threats.size)

        viewModel.searchTextChanged("Prompt")
        assertEquals("filter must not have applied yet — it's debounced", 3, viewModel.threats.size)

        advanceTimeBy(400)
        assertEquals(listOf("LLM01:2025"), viewModel.threats.map { it.code })
    }
}
