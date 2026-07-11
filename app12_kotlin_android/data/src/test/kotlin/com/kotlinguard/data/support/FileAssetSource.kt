package com.kotlinguard.data.support

import com.kotlinguard.data.assets.AssetSource
import java.io.File
import java.util.UUID

/**
 * Plain-JVM `AssetSource` backed by `java.io.File` — unlike Swift/SwiftData
 * (a pure library with no OS dependency, so `SwiftGuardDataTests` runs via
 * `swift test` alone), Room fundamentally needs an Android runtime, so
 * these JVM unit tests can't get away with zero Android dependency the way
 * app11's package tests do (see `Robolectric*Test` base classes for the
 * Room-touching half of this suite). This class, at least, needs nothing
 * Android-specific at all — it's how the pure-logic tests below (card
 * decoding, curation, reference validation) run with no Robolectric.
 */
class FileAssetSource(private val root: File) : AssetSource {
    override fun readText(path: String): String? {
        val file = File(root, path)
        return if (file.isFile) file.readText(Charsets.UTF_8) else null
    }

    override fun listFiles(directory: String): List<String> =
        File(root, directory).list()?.toList() ?: emptyList()

    companion object {
        /**
         * The REAL bundled content in `app/src/main/assets/` — not a
         * synthetic duplicate — reached via a relative path from Gradle's
         * default unit-test working directory (`data/`, the module root).
         * If a future change ever sets a custom `workingDir` for the `:data`
         * test task, this path needs updating to match.
         */
        val real: FileAssetSource = FileAssetSource(File("../app/src/main/assets"))

        /** A temp-directory-backed fixture source for one-off negative-case tests. */
        fun fixture(files: Map<String, String>): FileAssetSource {
            val root = File(System.getProperty("java.io.tmpdir"), "kotlinguard-fixture-${UUID.randomUUID()}")
            for ((relativePath, contents) in files) {
                val file = File(root, relativePath)
                file.parentFile.mkdirs()
                file.writeText(contents, Charsets.UTF_8)
            }
            return FileAssetSource(root)
        }
    }
}
