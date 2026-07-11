package com.kotlinguard.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.kotlinguard.data.model.MitigationEntity
import com.kotlinguard.ui.locale.LocalLocaleManager
import com.kotlinguard.ui.viewmodel.ThreatDetailViewModel
import com.kotlinguard.ui.viewmodel.ThreatDetailViewModelFactory

@Composable
fun ThreatDetailScreen(factory: ThreatDetailViewModelFactory, threatCode: String) {
    val viewModel: ThreatDetailViewModel = viewModel(factory = factory)
    val localeManager = LocalLocaleManager.current
    LaunchedEffect(threatCode) { viewModel.load() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(threatCode) },
                actions = {
                    IconButton(onClick = { viewModel.toggleBookmark() }) {
                        Icon(
                            if (viewModel.isBookmarked) Icons.Filled.Bookmark else Icons.Filled.BookmarkBorder,
                            contentDescription = "Bookmark"
                        )
                    }
                }
            )
        }
    ) { padding ->
        val threat = viewModel.threat ?: return@Scaffold
        Column(
            modifier = Modifier
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                Text(threat.title, style = androidx.compose.material3.MaterialTheme.typography.titleLarge)
                SeverityBadge(threat.severity)
            }

            Section("Przegląd / Overview") {
                Text(threat.localizedDescription(localeManager.currentLocale))
            }
            Section("Wektory Ataku / Attack Vectors") {
                Text(threat.attackVector)
                Text("Powierzchnia Ataku / Attack Surface", fontWeight = FontWeight.Bold)
                Text(threat.attackSurface)
            }
            Section("Mitigacje / Mitigations") {
                if (viewModel.mitigations.isEmpty()) {
                    Text("Brak jeszcze zdefiniowanych mitigacji dla tego zagrożenia.")
                }
                viewModel.mitigations.forEach { mitigation ->
                    MitigationCard(
                        mitigation = mitigation,
                        codeSamples = viewModel.codeSamplesByMitigation[mitigation.slug].orEmpty(),
                        revealedIds = viewModel.revealedAttackDemoIds,
                        onReveal = viewModel::revealAttackDemo
                    )
                }
            }
            Section("Powiązania Cross-Framework / Cross-Framework References") {
                if (viewModel.crossReferences.isEmpty()) {
                    Text("Brak jeszcze zdefiniowanych powiązań dla tego zagrożenia.")
                }
                viewModel.crossReferences.forEach { ref ->
                    Column(modifier = Modifier.padding(vertical = 4.dp)) {
                        Text(
                            "${ref.relationshipType.name} — ${ref.targetThreatCode}: ${ref.targetThreatTitle}",
                            fontWeight = FontWeight.Bold
                        )
                        Text(ref.description)
                    }
                }
            }
        }
    }
}

@Composable
private fun Section(title: String, content: @Composable () -> Unit) {
    Column(modifier = Modifier.padding(vertical = 8.dp)) {
        Text(title, style = androidx.compose.material3.MaterialTheme.typography.titleMedium)
        content()
    }
}

@Composable
private fun MitigationCard(
    mitigation: MitigationEntity,
    codeSamples: List<com.kotlinguard.data.model.CodeSampleEntity>,
    revealedIds: Set<Long>,
    onReveal: (Long) -> Unit
) {
    Column(modifier = Modifier.padding(vertical = 4.dp)) {
        Text(mitigation.title, fontWeight = FontWeight.Bold)
        Text(mitigation.description)
        Text("Typ/Type: ${mitigation.mitigationType.name} · Nakład/Effort: ${mitigation.effort.name} · Skuteczność/Effectiveness: ${mitigation.effectiveness.name}")
        CodeSamplePanel(codeSamples = codeSamples, revealedIds = revealedIds, onReveal = onReveal)
    }
}
