package com.kotlinguard.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Divider
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.kotlinguard.ui.locale.LocalLocaleManager
import com.kotlinguard.ui.viewmodel.CardSuitViewModel
import com.kotlinguard.ui.viewmodel.ViewModelFactory

@Composable
fun CardSuitScreen(factory: ViewModelFactory, edition: String, title: String) {
    val viewModel: CardSuitViewModel = viewModel(factory = factory)
    val localeManager = LocalLocaleManager.current
    LaunchedEffect(edition) { viewModel.loadEdition(edition) }

    Scaffold(topBar = { TopAppBar(title = { Text(title) }) }) { padding ->
        LazyColumn(modifier = Modifier.padding(padding)) {
            items(viewModel.cards) { card ->
                Column(modifier = Modifier.padding(16.dp)) {
                    Row {
                        Text("${card.cardId} (${card.value})", fontWeight = FontWeight.Bold)
                        card.kind.severityOrNull()?.let {
                            Text("  ")
                            SeverityBadge(it)
                        }
                    }
                    Text(card.localizedDescription(localeManager.currentLocale))
                    if (card.owaspRefs.isNotEmpty() || card.mitreRefs.isNotEmpty()) {
                        Text((card.owaspRefs + card.mitreRefs).joinToString(", "))
                    }
                }
                Divider()
            }
        }
    }
}
