package com.kotlinguard.ui.viewmodel

import com.kotlinguard.ui.support.FakeBookmarkRepository
import com.kotlinguard.ui.support.FakeCodeSampleRepository
import com.kotlinguard.ui.support.FakeMitigationRepository
import com.kotlinguard.ui.support.FakeThreatRepository
import com.kotlinguard.ui.support.MainDispatcherRule
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test

class ThreatDetailViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun loadPopulatesTheMatchingThreat() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = ThreatDetailViewModel(
            FakeThreatRepository(), FakeMitigationRepository(), FakeBookmarkRepository(),
            FakeCodeSampleRepository(), "LLM01:2025"
        )
        viewModel.load()
        assertEquals("Prompt Injection", viewModel.threat?.title)
    }

    @Test
    fun loadWithAnUnknownCodeLeavesThreatNull() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = ThreatDetailViewModel(
            FakeThreatRepository(), FakeMitigationRepository(), FakeBookmarkRepository(),
            FakeCodeSampleRepository(), "DOES_NOT_EXIST"
        )
        viewModel.load()
        assertNull(viewModel.threat)
    }

    @Test
    fun toggleBookmarkFlipsIsBookmarked() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = ThreatDetailViewModel(
            FakeThreatRepository(), FakeMitigationRepository(), FakeBookmarkRepository(),
            FakeCodeSampleRepository(), "LLM01:2025"
        )
        viewModel.load()
        assertEquals(false, viewModel.isBookmarked)
        viewModel.toggleBookmark()
        assertEquals(true, viewModel.isBookmarked)
    }
}
