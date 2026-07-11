package com.kotlinguard.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kotlinguard.data.model.Severity

@Composable
fun SeverityBadge(severity: Severity, modifier: Modifier = Modifier) {
    val color = when (severity) {
        Severity.CRITICAL -> Color(0xFFB00020)
        Severity.HIGH -> Color(0xFFE65100)
        Severity.MEDIUM -> Color(0xFFF9A825)
        Severity.LOW -> Color(0xFF2E7D32)
        Severity.INFO -> Color(0xFF546E7A)
    }
    Text(
        text = severity.name,
        color = Color.White,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        modifier = modifier
            .background(color, RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 2.dp)
    )
}
