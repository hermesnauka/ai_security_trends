package com.kotlinguard.ui.viewmodel

import com.kotlinguard.ui.support.FakeFrameworkRepository
import com.kotlinguard.ui.support.MainDispatcherRule
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test

class FrameworkListViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun loadPopulatesFrameworksFromTheRepository() = runTest(mainDispatcherRule.testDispatcher) {
        val viewModel = FrameworkListViewModel(FakeFrameworkRepository())
        viewModel.load() // runs eagerly under UnconfinedTestDispatcher — no advance needed

        assertEquals(setOf("OWASP_LLM", "OWASP_WEB"), viewModel.frameworks.map { it.code }.toSet())
        assertNull(viewModel.errorMessage)
    }
}
