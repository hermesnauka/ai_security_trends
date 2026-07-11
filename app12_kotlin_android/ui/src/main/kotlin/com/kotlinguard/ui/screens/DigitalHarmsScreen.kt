package com.kotlinguard.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Divider
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.kotlinguard.ui.locale.LocalLocaleManager
import com.kotlinguard.ui.viewmodel.CardSuitViewModel
import com.kotlinguard.ui.viewmodel.ViewModelFactory

/**
 * US-19: dedicated, not routed through `CardSuitScreen` — this deck must
 * NEVER render a severity badge (FR-19.2), and `CardKind.severityOrNull()`
 * is structurally always `null` for every card here (D-03's `DesignHarm`
 * variant carries no `Severity`), so there is no field to print even by
 * copy-paste mistake.
 */
@Composable
fun DigitalHarmsScreen(factory: ViewModelFactory) {
    val viewModel: CardSuitViewModel = viewModel(factory = factory)
    val localeManager = LocalLocaleManager.current
    val suitOrder = listOf("SCO", "ARC", "AGE", "TRU", "POR")
    LaunchedEffect(Unit) { viewModel.loadEdition("dbd") }

    Scaffold(topBar = { TopAppBar(title = { Text("Digital-by-Default Harms") }) }) { padding ->
        LazyColumn(modifier = Modifier.padding(padding)) {
            item {
                Text(
                    "Ta talia nie jest listą podatności technicznych z poziomem severity — modeluje harmy " +
                        "projektowe (wykluczenie cyfrowe, nieprzejrzyste projektowanie) w usługach publicznych, " +
                        "mapowane na OWASP A04:2021 Insecure Design.",
                    modifier = Modifier.padding(16.dp)
                )
            }
            suitOrder.forEach { suit ->
                item { Text(suit, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) }
                items(viewModel.cards.filter { it.suitCode == suit }) { card ->
                    Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                        Row {
                            Text(card.cardId, fontWeight = FontWeight.Bold)
                            Text(
                                "  harm projektowy",
                                color = Color(0xFF7B1FA2),
                                modifier = Modifier
                                    .background(Color(0x337B1FA2), RoundedCornerShape(4.dp))
                                    .padding(horizontal = 4.dp)
                            )
                        }
                        Text(card.localizedDescription(localeManager.currentLocale))
                        if (card.owaspRefs.isNotEmpty()) Text(card.owaspRefs.joinToString(", "))
                    }
                    Divider()
                }
            }
        }
    }
}
