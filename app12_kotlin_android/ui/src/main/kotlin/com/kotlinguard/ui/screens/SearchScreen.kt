package com.kotlinguard.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Divider
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.kotlinguard.data.repository.SearchResult
import com.kotlinguard.ui.locale.LocalLocaleManager
import com.kotlinguard.ui.viewmodel.SearchViewModel
import com.kotlinguard.ui.viewmodel.ViewModelFactory

@Composable
fun SearchScreen(
    factory: ViewModelFactory,
    onThreatSelected: (String) -> Unit
) {
    val viewModel: SearchViewModel = viewModel(factory = factory)
    val localeManager = LocalLocaleManager.current

    Scaffold(topBar = { TopAppBar(title = { Text("Szukaj / Search") }) }) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            OutlinedTextField(
                value = viewModel.queryText,
                onValueChange = { viewModel.queryChanged(it, localeManager.currentLocale) },
                label = { Text("Szukaj / Search") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp)
            )
            LazyColumn {
                items(viewModel.results) { result ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable(enabled = result.kind == SearchResult.Kind.THREAT) { onThreatSelected(result.code) }
                            .padding(16.dp)
                    ) {
                        Text(result.title, fontWeight = FontWeight.Bold)
                        Text(result.excerpt)
                    }
                    Divider()
                }
            }
        }
    }
}
