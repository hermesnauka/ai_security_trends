package com.kotlinguard.data.integrity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

/** NIST/well-known SHA-256 test vectors — mirrors app11's `HashingTests`. */
class HashingTest {
    @Test
    fun emptyStringVector() {
        assertEquals(
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            Hashing.sha256Hex("")
        )
    }

    @Test
    fun abcVector() {
        assertEquals(
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
            Hashing.sha256Hex("abc")
        )
    }

    @Test
    fun isDeterministic() {
        assertEquals(Hashing.sha256Hex("VE3|3|url|desc|misc"), Hashing.sha256Hex("VE3|3|url|desc|misc"))
    }

    @Test
    fun differentInputsProduceDifferentHashes() {
        assertNotEquals(Hashing.sha256Hex("VE3"), Hashing.sha256Hex("VE4"))
    }
}
