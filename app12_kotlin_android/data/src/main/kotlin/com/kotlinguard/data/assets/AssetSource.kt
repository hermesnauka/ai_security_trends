package com.kotlinguard.data.assets

import android.content.Context
import java.io.FileNotFoundException

/**
 * Thin abstraction over `Context.assets` — the Android equivalent of
 * `Bundle.main` on the Swift twin. Kept as an interface so `:data`'s unit
 * tests (JVM, no Android `Context`) can supply a fake backed by test
 * resources instead of Robolectric.
 */
interface AssetSource {
    fun readText(path: String): String?
    fun listFiles(directory: String): List<String>
}

class AndroidAssetSource(private val context: Context) : AssetSource {
    override fun readText(path: String): String? = try {
        context.assets.open(path).bufferedReader(Charsets.UTF_8).use { it.readText() }
    } catch (e: FileNotFoundException) {
        null
    }

    override fun listFiles(directory: String): List<String> =
        context.assets.list(directory)?.toList() ?: emptyList()
}
