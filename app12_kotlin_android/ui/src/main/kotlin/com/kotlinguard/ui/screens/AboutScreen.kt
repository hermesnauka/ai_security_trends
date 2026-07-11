package com.kotlinguard.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun AboutScreen() {
    Scaffold(topBar = { TopAppBar(title = { Text("O aplikacji / About") }) }) { padding ->
        Column(modifier = Modifier.padding(padding).padding(16.dp)) {
            Text("KotlinGuard 2026", fontWeight = FontWeight.Bold)
            Text(
                "Aplikacja edukacyjna prezentująca zagrożenia bezpieczeństwa i mitigacje wg OWASP, " +
                    "MITRE ATLAS oraz CompTIA Security+/SecAI+ na rok 2026, wraz z przykładami kodu w " +
                    "Pythonie, Javie, Go, Scali i Lua.\n\n" +
                    "An educational app presenting security threats and mitigations per OWASP, MITRE ATLAS, " +
                    "and CompTIA Security+/SecAI+ for 2026, with code samples in Python, Java, Go, Scala, and Lua."
            )
            LanguageToggle()
        }
    }
}
