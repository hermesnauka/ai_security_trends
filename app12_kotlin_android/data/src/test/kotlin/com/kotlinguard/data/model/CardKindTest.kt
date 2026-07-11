package com.kotlinguard.data.model

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * D-03: exercises the exhaustive-`when` guarantee at the value level — the
 * Kotlin compiler already guarantees no third `CardKind` subtype can exist
 * outside this sealed interface's two declared members.
 */
class CardKindTest {
    @Test
    fun technicalThreatExposesItsSeverity() {
        val kind: CardKind = CardKind.TechnicalThreat(Severity.CRITICAL)
        assertEquals(Severity.CRITICAL, kind.severityOrNull())
        assertFalse(kind.isDesignHarm)
    }

    @Test
    fun designHarmHasNoSeverity() {
        val kind: CardKind = CardKind.DesignHarm
        assertNull(kind.severityOrNull())
        assertTrue(kind.isDesignHarm)
    }

    @Test
    fun codableRoundTrip() {
        val json = Json { encodeDefaults = true }
        val original: CardKind = CardKind.TechnicalThreat(Severity.HIGH)
        val encoded = json.encodeToString(original)
        val decoded = json.decodeFromString(CardKind.serializer(), encoded)
        assertEquals(original, decoded)
    }

    @Test
    fun designHarmCodableRoundTrip() {
        val json = Json { encodeDefaults = true }
        val encoded = json.encodeToString<CardKind>(CardKind.DesignHarm)
        val decoded = json.decodeFromString(CardKind.serializer(), encoded)
        assertEquals(CardKind.DesignHarm, decoded)
    }
}
