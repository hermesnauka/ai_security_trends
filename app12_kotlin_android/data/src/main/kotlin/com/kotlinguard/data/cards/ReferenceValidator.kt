package com.kotlinguard.data.cards

import com.kotlinguard.data.assets.AssetSource
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * SR-07-equivalent: owaspRefs/mitreRefs values are validated against
 * allowlists bundled as Android assets before any card row is written —
 * the same guard app09's Reference_Validator and app11's ReferenceValidator
 * provide, since every one of these values is curated content (PLAN.md
 * §0.1), never extracted from the raw YAML.
 */
class ReferenceValidator(assetSource: AssetSource) {
    private val owaspAllowlist: Set<String> = loadAllowlist(assetSource, "ref-allowlists.json", "owasp_refs")
    private val mitreAllowlist: Set<String> = loadAllowlist(assetSource, "mitre-atlas-allowlist.json", "mitre_refs")

    fun assertOwaspRefsValid(refs: List<String>, cardId: String) {
        for (ref in refs) {
            if (ref !in owaspAllowlist) throw CardDecodeError.UnknownReference(ref, "owasp_refs", cardId)
        }
    }

    fun assertMitreRefsValid(refs: List<String>, cardId: String) {
        for (ref in refs) {
            if (ref !in mitreAllowlist) throw CardDecodeError.UnknownReference(ref, "mitre_refs", cardId)
        }
    }

    private companion object {
        fun loadAllowlist(assetSource: AssetSource, fileName: String, key: String): Set<String> {
            val text = assetSource.readText(fileName) ?: return emptySet()
            val root = Json.parseToJsonElement(text).jsonObject
            return root[key]?.jsonArray?.map { it.jsonPrimitive.content }?.toSet() ?: emptySet()
        }
    }
}
