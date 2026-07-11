package com.kotlinguard.data.cards

import com.kotlinguard.data.support.FileAssetSource
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

/**
 * SR-07-equivalent: exercises `ReferenceValidator` against the REAL bundled
 * `ref-allowlists.json`/`mitre-atlas-allowlist.json` (via `FileAssetSource.real`,
 * a relative path into `app/src/main/assets/` — no fixture duplicate).
 */
class ReferenceValidatorTest {
    private val validator = ReferenceValidator(FileAssetSource.real)

    @Test
    fun acceptsAKnownOwaspRef() {
        validator.assertOwaspRefsValid(listOf("A03:2021"), "TEST")
    }

    @Test
    fun acceptsAKnownMitreRef() {
        validator.assertMitreRefsValid(listOf("AML.T0051"), "TEST")
    }

    @Test
    fun rejectsAnUnknownOwaspRef() {
        val error = assertThrows(CardDecodeError.UnknownReference::class.java) {
            validator.assertOwaspRefsValid(listOf("A99:2099"), "TEST")
        }
        assertEquals("A99:2099", error.value)
        assertEquals("owasp_refs", error.field)
        assertEquals("TEST", error.cardId)
    }

    @Test
    fun rejectsAnUnknownMitreRef() {
        assertThrows(CardDecodeError.UnknownReference::class.java) {
            validator.assertMitreRefsValid(listOf("AML.T9999"), "TEST")
        }
    }

    @Test
    fun emptyRefsListNeverThrows() {
        validator.assertOwaspRefsValid(emptyList(), "TEST")
        validator.assertMitreRefsValid(emptyList(), "TEST")
    }
}
