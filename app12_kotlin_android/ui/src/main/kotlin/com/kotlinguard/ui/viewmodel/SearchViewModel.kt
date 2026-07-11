package com.kotlinguard.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kotlinguard.data.model.AppLocale
import com.kotlinguard.data.repository.SearchRepository
import com.kotlinguard.data.repository.SearchResult
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class SearchViewModel(private val repository: SearchRepository) : ViewModel() {
    var queryText by mutableStateOf("")
        private set
    var results by mutableStateOf<List<SearchResult>>(emptyList())
        private set

    private var debounceJob: Job? = null

    fun queryChanged(text: String, locale: AppLocale) {
        queryText = text
        debounceJob?.cancel()
        if (text.isBlank()) {
            results = emptyList()
            return
        }
        debounceJob = viewModelScope.launch {
            delay(300)
            results = repository.query(text, locale)
        }
    }
}
