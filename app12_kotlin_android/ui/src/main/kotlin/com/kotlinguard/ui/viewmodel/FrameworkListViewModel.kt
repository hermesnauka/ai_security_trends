package com.kotlinguard.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kotlinguard.data.model.FrameworkEntity
import com.kotlinguard.data.repository.FrameworkRepository
import kotlinx.coroutines.launch

class FrameworkListViewModel(private val repository: FrameworkRepository) : ViewModel() {
    var frameworks by mutableStateOf<List<FrameworkEntity>>(emptyList())
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set

    fun load() {
        viewModelScope.launch {
            try {
                frameworks = repository.list()
            } catch (e: Exception) {
                errorMessage = e.message
            }
        }
    }
}
