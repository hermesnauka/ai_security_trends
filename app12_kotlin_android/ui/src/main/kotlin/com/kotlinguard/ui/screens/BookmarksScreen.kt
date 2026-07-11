package com.kotlinguard.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.kotlinguard.ui.viewmodel.BookmarksViewModel
import com.kotlinguard.ui.viewmodel.ViewModelFactory

@Composable
fun BookmarksScreen(factory: ViewModelFactory, onItemSelected: (String) -> Unit) {
    val viewModel: BookmarksViewModel = viewModel(factory = factory)
    LaunchedEffect(Unit) { viewModel.load() }

    Scaffold(topBar = { TopAppBar(title = { Text("Zakładki / Bookmarks") }) }) { padding ->
        LazyColumn(modifier = Modifier.padding(padding)) {
            items(viewModel.bookmarks) { bookmark ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onItemSelected(bookmark.threatOrCardCode) }
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(bookmark.threatOrCardCode)
                    IconButton(onClick = { viewModel.remove(bookmark.threatOrCardCode) }) {
                        Icon(Icons.Filled.Delete, contentDescription = "Remove")
                    }
                }
                Divider()
            }
        }
    }
}
