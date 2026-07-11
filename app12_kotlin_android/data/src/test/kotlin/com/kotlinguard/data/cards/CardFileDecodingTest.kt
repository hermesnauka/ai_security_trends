package com.kotlinguard.data.cards

import com.charleskorn.kaml.YamlException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * D-06: pins the exact behavior every raw Cornucopia YAML decode must have —
 * reject any unrecognized key at every nesting level (top-level, suit,
 * card). kotlinx.serialization + kaml reject unknown keys by default
 * (`strictMode = true`, `cardYaml` in `CardFile.kt`) — no hand-written
 * unknown-key check is needed the way app11_swift_ios's `DynamicKey`
 * container required (D-06).
 */
class CardFileDecodingTest {
    private val validYAML = """
        meta:
          edition: "webapp"
          component: "cards"
          language: "en"
          version: "3.0"
        suits:
        -
          id: "VE"
          name: "DATA VALIDATION & ENCODING"
          cards:
          -
            id: "VE2"
            value: "2"
            url: "https://cornucopia.owasp.org/cards/VE2"
            desc: "Some threat description."
            misc: "A note."
    """.trimIndent()

    @Test
    fun decodesAValidDeck() {
        val cardFile = cardYaml.decodeFromString(CardFile.serializer(), validYAML)
        assertEquals("webapp", cardFile.meta.edition)
        assertEquals(1, cardFile.suits.size)
        assertEquals(1, cardFile.suits[0].cards?.size)
        assertEquals("VE2", cardFile.suits[0].cards?.get(0)?.id)
    }

    @Test(expected = YamlException::class)
    fun rejectsUnrecognizedTopLevelKey() {
        val yaml = "$validYAML\nextra_top_level_key: \"evil\"\n"
        cardYaml.decodeFromString(CardFile.serializer(), yaml)
    }

    @Test(expected = YamlException::class)
    fun rejectsUnrecognizedSuitKey() {
        val yaml = """
            meta:
              edition: "webapp"
              component: "cards"
              language: "en"
              version: "3.0"
            suits:
            -
              id: "VE"
              name: "DATA VALIDATION & ENCODING"
              unexpected_suit_field: "evil"
              cards: []
        """.trimIndent()
        cardYaml.decodeFromString(CardFile.serializer(), yaml)
    }

    @Test(expected = YamlException::class)
    fun rejectsUnrecognizedCardKey() {
        val yaml = """
            meta:
              edition: "webapp"
              component: "cards"
              language: "en"
              version: "3.0"
            suits:
            -
              id: "VE"
              name: "DATA VALIDATION & ENCODING"
              cards:
              -
                id: "VE2"
                value: "2"
                desc: "desc"
                unexpected_card_field: "evil"
        """.trimIndent()
        cardYaml.decodeFromString(CardFile.serializer(), yaml)
    }

    /**
     * The "Common"/metadata suit has `sentences` instead of `cards` — it
     * carries no threat data and must decode successfully with `cards ==
     * null`, not be treated as a decode error.
     */
    @Test
    fun metadataSuitWithSentencesDecodesWithNullCards() {
        val yaml = """
            meta:
              edition: "webapp"
              component: "cards"
              language: "en"
              version: "3.0"
            suits:
            -
              id: "Common"
              name: "Common"
              sentences: ["Deck title blurb."]
        """.trimIndent()
        val cardFile = cardYaml.decodeFromString(CardFile.serializer(), yaml)
        assertNull(cardFile.suits[0].cards)
    }
}
