package com.kotlinguard.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kotlinguard.data.model.BookmarkEntity
import com.kotlinguard.data.repository.BookmarkRepository
import kotlinx.coroutines.launch

class BookmarksViewModel(private val repository: BookmarkRepository) : ViewModel() {
    var bookmarks by mutableStateOf<List<BookmarkEntity>>(emptyList())
        private set

    fun load() {
        viewModelScope.launch { bookmarks = repository.list() }
    }

    fun remove(code: String) {
        viewModelScope.launch {
            repository.remove(code)
            load()
        }
    }
}
