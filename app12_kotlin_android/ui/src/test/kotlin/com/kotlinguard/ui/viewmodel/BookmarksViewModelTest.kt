package com.kotlinguard.ui.viewmodel

import com.kotlinguard.ui.support.FakeBookmarkRepository
import com.kotlinguard.ui.support.MainDispatcherRule
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class BookmarksViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun loadPopulatesBookmarks() = runTest(mainDispatcherRule.testDispatcher) {
        val repository = FakeBookmarkRepository()
        repository.add("A01:2021")
        val viewModel = BookmarksViewModel(repository)
        viewModel.load()
        assertTrue(viewModel.bookmarks.any { it.threatOrCardCode == "A01:2021" })
    }

    @Test
    fun removeReloadsTheList() = runTest(mainDispatcherRule.testDispatcher) {
        val repository = FakeBookmarkRepository()
        repository.add("A01:2021")
        val viewModel = BookmarksViewModel(repository)
        viewModel.load()
        viewModel.remove("A01:2021")
        assertTrue(viewModel.bookmarks.isEmpty())
    }
}
