package com.kotlinguard.ui.screens

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import com.kotlinguard.data.model.AppLocale
import com.kotlinguard.ui.locale.LocalLocaleManager

@Composable
fun LanguageToggle() {
    val localeManager = LocalLocaleManager.current
    val options = listOf(AppLocale.POLISH, AppLocale.ENGLISH)

    SingleChoiceSegmentedButtonRow(modifier = androidx.compose.ui.Modifier.padding(8.dp)) {
        options.forEachIndexed { index, locale ->
            SegmentedButton(
                selected = localeManager.currentLocale == locale,
                onClick = { localeManager.setLocale(locale) },
                shape = SegmentedButtonDefaults.itemShape(index = index, count = options.size)
            ) {
                Text(locale.code.uppercase())
            }
        }
    }
}
