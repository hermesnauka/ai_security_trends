package com.kotlinguard.ui.viewmodel

import com.kotlinguard.data.model.AppLocale
import com.kotlinguard.data.repository.SearchResult
import com.kotlinguard.ui.support.FakeSearchRepository
import com.kotlinguard.ui.support.MainDispatcherRule
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class SearchViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun blankQueryProducesNoResults() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = SearchViewModel(FakeSearchRepository())
        viewModel.queryChanged("   ", AppLocale.ENGLISH)
        assertTrue(viewModel.results.isEmpty())
    }

    @Test
    fun queryDebouncesThenFindsAMatch() = runTest(mainDispatcherRule.testDispatcher) {
        val results = listOf(
            SearchResult(code = "LLM01:2025", title = "Prompt Injection", excerpt = "...", kind = SearchResult.Kind.THREAT)
        )
        val viewModel = SearchViewModel(FakeSearchRepository(results))
        viewModel.queryChanged("Prompt", AppLocale.ENGLISH)
        assertTrue("must not have applied yet — it's debounced", viewModel.results.isEmpty())

        advanceTimeBy(400)
        assertTrue(viewModel.results.any { it.code == "LLM01:2025" })
    }
}
