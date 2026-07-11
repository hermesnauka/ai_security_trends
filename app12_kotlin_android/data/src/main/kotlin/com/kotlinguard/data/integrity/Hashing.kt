package com.kotlinguard.data.integrity

import java.security.MessageDigest

/**
 * `java.security.MessageDigest` is part of the JDK/Android platform — no
 * third-party crypto dependency needed for SHA-256, the same "free" property
 * app11 gets from Apple's `CryptoKit`, and every server-based sibling had to
 * pick a library for.
 */
object Hashing {
    fun sha256Hex(input: String): String = sha256Hex(input.toByteArray(Charsets.UTF_8))

    fun sha256Hex(data: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(data).joinToString("") { "%02x".format(it) }
}
