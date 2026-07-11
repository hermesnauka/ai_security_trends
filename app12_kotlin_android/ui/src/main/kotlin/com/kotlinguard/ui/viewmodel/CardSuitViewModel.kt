package com.kotlinguard.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kotlinguard.data.model.CornucopiaCardEntity
import com.kotlinguard.data.repository.CardRepository
import kotlinx.coroutines.launch

class CardSuitViewModel(private val repository: CardRepository) : ViewModel() {
    var cards by mutableStateOf<List<CornucopiaCardEntity>>(emptyList())
        private set

    fun loadSuit(suitCode: String) {
        viewModelScope.launch { cards = repository.bySuit(suitCode) }
    }

    fun loadEdition(edition: String) {
        viewModelScope.launch { cards = repository.byEdition(edition) }
    }
}
