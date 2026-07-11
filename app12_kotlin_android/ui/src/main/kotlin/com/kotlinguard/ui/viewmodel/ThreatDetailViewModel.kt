package com.kotlinguard.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kotlinguard.data.di.DataContainer
import com.kotlinguard.data.model.CodeSampleEntity
import com.kotlinguard.data.model.CrossReferenceEntity
import com.kotlinguard.data.model.MitigationEntity
import com.kotlinguard.data.model.ThreatEntity
import com.kotlinguard.data.repository.BookmarkRepository
import com.kotlinguard.data.repository.MitigationRepository
import com.kotlinguard.data.repository.ThreatRepository
import kotlinx.coroutines.launch

class ThreatDetailViewModel(
    private val threatRepository: ThreatRepository,
    private val mitigationRepository: MitigationRepository,
    private val bookmarkRepository: BookmarkRepository,
    private val dataContainer: DataContainer,
    private val threatCode: String
) : ViewModel() {
    var threat by mutableStateOf<ThreatEntity?>(null)
        private set
    var mitigations by mutableStateOf<List<MitigationEntity>>(emptyList())
        private set
    var codeSamplesByMitigation by mutableStateOf<Map<String, List<CodeSampleEntity>>>(emptyMap())
        private set
    var crossReferences by mutableStateOf<List<CrossReferenceEntity>>(emptyList())
        private set
    var isBookmarked by mutableStateOf(false)
        private set

    /**
     * FR-16.4/attack-demo-gate-equivalent: which code samples the user has
     * explicitly confirmed viewing, mirroring app11's `revealedAttackDemoIDs`
     * — Room rows have a stable `Long` id, the same role `PersistentIdentifier`
     * plays in the SwiftData twin.
     */
    var revealedAttackDemoIds by mutableStateOf<Set<Long>>(emptySet())
        private set

    fun load() {
        viewModelScope.launch {
            val loaded = threatRepository.detail(threatCode) ?: return@launch
            threat = loaded
            mitigations = mitigationRepository.forThreat(threatCode)
            crossReferences = threatRepository.crossReferences(threatCode)
            codeSamplesByMitigation = mitigations.associate { m ->
                m.slug to dataContainer.codeSamplesFor(m.slug)
            }
            isBookmarked = dataContainer.bookmarkRepository.list().any { it.threatOrCardCode == threatCode }
        }
    }

    fun toggleBookmark() {
        viewModelScope.launch {
            if (isBookmarked) bookmarkRepository.remove(threatCode) else bookmarkRepository.add(threatCode)
            isBookmarked = !isBookmarked
        }
    }

    fun revealAttackDemo(sampleId: Long) {
        revealedAttackDemoIds = revealedAttackDemoIds + sampleId
    }
}
