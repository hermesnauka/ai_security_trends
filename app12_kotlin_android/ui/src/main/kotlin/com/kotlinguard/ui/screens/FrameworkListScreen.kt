package com.kotlinguard.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
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
import com.kotlinguard.ui.viewmodel.FrameworkListViewModel
import com.kotlinguard.ui.viewmodel.ViewModelFactory

@Composable
fun FrameworkListScreen(
    factory: ViewModelFactory,
    onFrameworkSelected: (String) -> Unit
) {
    val viewModel: FrameworkListViewModel = viewModel(factory = factory)
    LaunchedEffect(Unit) { viewModel.load() }

    Scaffold(topBar = { TopAppBar(title = { Text("Frameworki / Frameworks") }) }) { padding ->
        LazyColumn(modifier = Modifier.padding(padding)) {
            items(viewModel.frameworks) { framework ->
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onFrameworkSelected(framework.code) }
                        .padding(16.dp)
                ) {
                    Text(framework.name, fontWeight = FontWeight.Bold)
                    Text("${framework.code} · v${framework.version}")
                }
                Divider()
            }
        }
    }
}
