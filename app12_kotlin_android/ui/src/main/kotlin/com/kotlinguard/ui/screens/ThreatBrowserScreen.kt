package com.kotlinguard.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Divider
import androidx.compose.material3.FilterChip
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.kotlinguard.data.model.Severity
import com.kotlinguard.ui.viewmodel.ThreatBrowserViewModel
import com.kotlinguard.ui.viewmodel.ViewModelFactory

@Composable
fun ThreatBrowserScreen(
    factory: ViewModelFactory,
    frameworkCode: String? = null,
    onThreatSelected: (String) -> Unit
) {
    val viewModel: ThreatBrowserViewModel = viewModel(factory = factory)
    LaunchedEffect(frameworkCode) {
        viewModel.selectedFrameworkCode = frameworkCode
        viewModel.load()
    }

    Scaffold(topBar = { TopAppBar(title = { Text("Zagrożenia / Threats") }) }) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            OutlinedTextField(
                value = viewModel.searchText,
                onValueChange = { viewModel.searchTextChanged(it) },
                label = { Text("Szukaj / Search") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp)
            )

            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.padding(horizontal = 8.dp)
            ) {
                items(Severity.entries) { severity ->
                    FilterChip(
                        selected = viewModel.selectedSeverity == severity,
                        onClick = {
                            viewModel.severityChanged(if (viewModel.selectedSeverity == severity) null else severity)
                        },
                        label = { Text(severity.name) }
                    )
                }
            }

            LazyColumn {
                items(viewModel.threats) { threat ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onThreatSelected(threat.code) }
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(threat.code, fontWeight = FontWeight.Bold)
                            Text(threat.title)
                        }
                        SeverityBadge(threat.severity)
                    }
                    Divider()
                }
            }
        }
    }
}
