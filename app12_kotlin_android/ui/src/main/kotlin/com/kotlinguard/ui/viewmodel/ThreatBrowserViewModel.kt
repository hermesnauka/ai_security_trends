package com.kotlinguard.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kotlinguard.data.model.Severity
import com.kotlinguard.data.model.ThreatEntity
import com.kotlinguard.data.repository.ThreatFilter
import com.kotlinguard.data.repository.ThreatRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class ThreatBrowserViewModel(
    private val repository: ThreatRepository,
    var selectedFrameworkCode: String? = null
) : ViewModel() {
    var searchText by mutableStateOf("")
        private set
    var selectedSeverity by mutableStateOf<Severity?>(null)
        private set
    var threats by mutableStateOf<List<ThreatEntity>>(emptyList())
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set

    private var debounceJob: Job? = null

    fun load() {
        applyFilter()
    }

    fun severityChanged(severity: Severity?) {
        selectedSeverity = severity
        applyFilter()
    }

    /**
     * FR-02.4-equivalent: debounces at ~300ms, the same interval
     * `threat-browser.js` used in app09 and app11's `Task.sleep` — here a
     * cancellable coroutine `Job` plays the same role.
     */
    fun searchTextChanged(text: String) {
        searchText = text
        debounceJob?.cancel()
        debounceJob = viewModelScope.launch {
            delay(300)
            applyFilter()
        }
    }

    private fun applyFilter() {
        viewModelScope.launch {
            try {
                threats = repository.list(
                    ThreatFilter(
                        frameworkCode = selectedFrameworkCode,
                        severity = selectedSeverity,
                        query = searchText.ifEmpty { null }
                    )
                )
            } catch (e: Exception) {
                errorMessage = e.message
            }
        }
    }
}
