package com.kotlinguard.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.kotlinguard.ui.locale.LocalLocaleManager
import com.kotlinguard.ui.locale.LocaleManager
import com.kotlinguard.ui.screens.RootScreen
import com.kotlinguard.ui.viewmodel.ViewModelFactory

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val app = application as KotlinGuardApplication

        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    var isSeeded by remember { mutableStateOf(app.seedingJob.isCompleted) }
                    LaunchedEffect(Unit) {
                        app.seedingJob.join()
                        isSeeded = true
                    }

                    if (!isSeeded) {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator()
                        }
                    } else {
                        val localeManager = remember { LocaleManager() }
                        CompositionLocalProvider(LocalLocaleManager provides localeManager) {
                            val factory = remember { ViewModelFactory(app.dataContainer) }
                            RootScreen(factory, app.dataContainer)
                        }
                    }
                }
            }
        }
    }
}
