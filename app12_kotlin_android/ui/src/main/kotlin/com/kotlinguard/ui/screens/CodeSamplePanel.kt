package com.kotlinguard.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.kotlinguard.data.model.CodeLanguage
import com.kotlinguard.data.model.CodeSampleEntity
import com.kotlinguard.data.model.SampleType

/**
 * D-08: every code sample ships read-only, bundled, never executed. The
 * attack-demo confirmation is a Material `AlertDialog` — the Compose
 * analogue of app11's native `.confirmationDialog`; unlike app09's web
 * equivalent there is no "must also work with JavaScript disabled"
 * constraint here (PLAN.md §0), so a modal is the natural, idiomatic gate.
 */
@Composable
fun CodeSamplePanel(
    codeSamples: List<CodeSampleEntity>,
    revealedIds: Set<Long>,
    onReveal: (Long) -> Unit
) {
    if (codeSamples.isEmpty()) {
        Text("Brak jeszcze próbek kodu dla tej mitigacji. / No code samples for this mitigation yet.")
        return
    }

    val availableLanguages = remember(codeSamples) { codeSamples.map { it.language }.distinct().sortedBy { it.name } }
    var selectedLanguage by rememberSaveable { mutableStateOf(availableLanguages.first()) }
    var pendingAttackDemo by remember { mutableStateOf<CodeSampleEntity?>(null) }

    Column {
        SingleChoiceSegmentedButtonRow {
            availableLanguages.forEachIndexed { index, language ->
                SegmentedButton(
                    selected = selectedLanguage == language,
                    onClick = { selectedLanguage = language },
                    shape = SegmentedButtonDefaults.itemShape(index = index, count = availableLanguages.size)
                ) {
                    Text(language.name)
                }
            }
        }

        codeSamples.filter { it.language == selectedLanguage }.forEach { sample ->
            if (sample.sampleType == SampleType.DEFENSE) {
                CodeBlock(sample)
            } else {
                AttackDemoBlock(
                    sample = sample,
                    revealed = revealedIds.contains(sample.id),
                    onRequestReveal = { pendingAttackDemo = sample }
                )
            }
        }
    }

    pendingAttackDemo?.let { sample ->
        AlertDialog(
            onDismissRequest = { pendingAttackDemo = null },
            title = { Text("Ten kod celowo demonstruje podatność. / This code deliberately demonstrates a vulnerability.") },
            text = { Text("Potwierdź, aby go zobaczyć. / Confirm to view it.") },
            confirmButton = {
                TextButton(
                    onClick = { onReveal(sample.id); pendingAttackDemo = null },
                    modifier = Modifier.testTag("attack-demo-confirm-button")
                ) { Text("Rozumiem / I understand") }
            },
            dismissButton = {
                TextButton(onClick = { pendingAttackDemo = null }) { Text("Anuluj / Cancel") }
            }
        )
    }
}

@Composable
private fun CodeBlock(sample: CodeSampleEntity, modifier: Modifier = Modifier) {
    Column(modifier = modifier.padding(vertical = 4.dp)) {
        Text(sample.title, fontWeight = FontWeight.Bold)
        Text(
            sample.code,
            fontFamily = FontFamily.Monospace,
            modifier = Modifier
                .horizontalScroll(rememberScrollState())
                .padding(4.dp)
        )
        Text("${sample.frameworkHint} — ${sample.versionNote}")
    }
}

@Composable
private fun AttackDemoBlock(sample: CodeSampleEntity, revealed: Boolean, onRequestReveal: () -> Unit) {
    Column(
        modifier = Modifier
            .padding(vertical = 4.dp)
            .background(Color(0x1AFF0000), RoundedCornerShape(6.dp))
            .padding(8.dp)
    ) {
        Text("ATTACK DEMO — kod podatny, nie używać w produkcji", color = Color.Red, fontWeight = FontWeight.Bold)
        if (revealed) {
            CodeBlock(sample, modifier = Modifier.testTag("attack-demo-code-body"))
        } else {
            OutlinedButton(
                onClick = onRequestReveal,
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red),
                border = BorderStroke(1.dp, Color.Red),
                modifier = Modifier.testTag("attack-demo-reveal-button")
            ) {
                Text("Pokaż kod (VULNERABLE)")
            }
        }
    }
}
