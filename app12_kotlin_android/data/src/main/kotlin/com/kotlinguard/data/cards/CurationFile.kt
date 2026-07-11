package com.kotlinguard.data.cards

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * One curated entry per card_id — severity/owaspRefs/mitreRefs never exist
 * in the raw YAML (PLAN.md §0.1); this is the reviewed file that supplies
 * them, merged with the raw card by `CardLoader`.
 */
@Serializable
data class CurationEntry(
    val severity: String? = null,
    val owasp_refs: List<String> = emptyList(),
    val mitre_refs: List<String> = emptyList()
)

/**
 * `_comment` is a reserved top-level key holding a plain string, not a card
 * entry. Unlike Swift's `KeyedDecodingContainer` (which needs a two-pass
 * `JSONSerialization` workaround, app11's D-06 note), kotlinx.serialization's
 * `JsonObject` is a `Map<String, JsonElement>` where each value's shape is
 * inspected independently at the point it's decoded — so filtering the
 * reserved key out and decoding the rest per-entry needs no special-casing
 * beyond the `if (key in reservedKeys) continue` below.
 */
object CurationFileLoader {
    private val reservedKeys = setOf("_comment")
    private val json = Json { ignoreUnknownKeys = false }

    fun load(text: String): Map<String, CurationEntry> {
        val root = json.parseToJsonElement(text).jsonObject
        val result = mutableMapOf<String, CurationEntry>()
        for ((cardId, element) in root) {
            if (cardId in reservedKeys) continue
            result[cardId] = json.decodeFromJsonElement(CurationEntry.serializer(), element)
        }
        return result
    }

    fun loadTranslations(text: String): Map<String, String> {
        val root = json.parseToJsonElement(text).jsonObject
        val result = mutableMapOf<String, String>()
        for ((cardId, element) in root) {
            if (cardId in reservedKeys) continue
            result[cardId] = element.jsonPrimitive.content
        }
        return result
    }
}
