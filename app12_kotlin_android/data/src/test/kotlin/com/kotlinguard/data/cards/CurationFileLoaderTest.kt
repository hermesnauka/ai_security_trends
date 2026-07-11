package com.kotlinguard.data.cards

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * `_comment` is a reserved top-level key holding a plain string, not a card
 * entry. Unlike app11_swift_ios's `JSONSerialization` two-pass workaround
 * (needed because `KeyedDecodingContainer` requires uniform value shapes),
 * kotlinx.serialization's `JsonObject` is a `Map<String, JsonElement>` whose
 * values are inspected independently at the point they're decoded — no
 * special-casing beyond `if (key in reservedKeys) continue` is needed.
 */
class CurationFileLoaderTest {
    @Test
    fun filtersOutReservedCommentKey() {
        val json = """
            {
              "_comment": "this is documentation, not a card entry",
              "VE3": { "severity": "critical", "owasp_refs": ["A03:2021"], "mitre_refs": [] }
            }
        """.trimIndent()
        val curation = CurationFileLoader.load(json)
        assertNull(curation["_comment"])
        assertEquals("critical", curation["VE3"]?.severity)
        assertEquals(listOf("A03:2021"), curation["VE3"]?.owasp_refs)
    }

    @Test
    fun defaultsMissingRefsToEmptyLists() {
        val json = """{ "VE4": { "severity": "high" } }"""
        val curation = CurationFileLoader.load(json)
        assertEquals(emptyList<String>(), curation["VE4"]?.owasp_refs)
        assertEquals(emptyList<String>(), curation["VE4"]?.mitre_refs)
    }

    @Test
    fun loadTranslationsFiltersCommentAndKeepsStrings() {
        val json = """
            {
              "_comment": "Reviewed Polish translations, per card_id.",
              "VE2": "Opis karty po polsku."
            }
        """.trimIndent()
        val translations = CurationFileLoader.loadTranslations(json)
        assertNull(translations["_comment"])
        assertEquals("Opis karty po polsku.", translations["VE2"])
    }
}
