package com.kotlinguard.data.cards

import com.charleskorn.kaml.Yaml
import com.charleskorn.kaml.YamlConfiguration
import kotlinx.serialization.Serializable

/**
 * D-06/§0.1: raw deck YAML shape is only
 * meta{edition,component,language,version} / suits[{id,name,cards[{id,value,url,desc,misc}]}].
 * kotlinx.serialization + kaml reject unrecognized keys by default (the
 * opposite default from Swift's synthesized `Decodable`, per app11's D-06)
 * — `strictMode = true` below is stated explicitly rather than relied on
 * implicitly, so this guarantee survives a kaml version bump that might
 * change its own default.
 */
val cardYaml = Yaml(configuration = YamlConfiguration(strictMode = true))

@Serializable
data class RawCard(
    val id: String,
    val value: String,
    val url: String? = null,
    val desc: String,
    val misc: String? = null
)

/**
 * The "Common"/metadata suit (e.g. deck title/version blurb) has a
 * `sentences` key instead of `cards` — it carries no threat data. `cards`
 * is optional for exactly that reason, and such suits are skipped during
 * extraction, not treated as a decode error (mirrors app09's Card_Loader
 * and app11's RawSuit).
 */
@Serializable
data class RawSuit(
    val id: String,
    val name: String,
    val cards: List<RawCard>? = null,
    val sentences: List<String>? = null
)

@Serializable
data class RawMeta(
    val edition: String,
    val component: String,
    val language: String,
    val version: String
)

@Serializable
data class CardFile(
    val meta: RawMeta,
    val suits: List<RawSuit>
)
