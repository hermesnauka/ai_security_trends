package com.kotlinguard.data.integrity

import com.kotlinguard.data.assets.AssetSource
import com.kotlinguard.data.db.ContentHashDao
import com.kotlinguard.data.model.ContentHashEntity
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Per PLAN.md §12: because the APK is signed by Google Play / a release
 * keystore and Android's per-app UID sandbox (unlike app11's App Sandbox,
 * but the same category of OS-level isolation) prevents another process
 * from modifying the installed package's assets post-install, this check's
 * primary value is catching a bad build/CI mistake before release and
 * detecting corruption of the on-device asset cache — not detecting a
 * malicious runtime tamperer, the primary concern for every server-based
 * sibling.
 */
class IntegrityChecker(
    private val assetSource: AssetSource,
    private val contentHashDao: ContentHashDao
) {
    /** @return fileName -> isValid */
    suspend fun verify(nowMillis: Long = System.currentTimeMillis()): Map<String, Boolean> {
        val hashesText = assetSource.readText("hashes.json") ?: return emptyMap()
        val expected = Json.parseToJsonElement(hashesText).jsonObject
            .mapValues { it.value.jsonPrimitive.content }

        val results = mutableMapOf<String, Boolean>()

        for ((fileName, expectedHash) in expected) {
            val bytes = assetSource.readText("cornucopia/$fileName")?.toByteArray(Charsets.UTF_8)
            val isValid = bytes != null && Hashing.sha256Hex(bytes) == expectedHash
            results[fileName] = isValid

            contentHashDao.upsert(
                ContentHashEntity(
                    fileName = fileName,
                    sha256Hash = expectedHash,
                    verifiedAt = nowMillis,
                    isValid = isValid
                )
            )
        }

        return results
    }

    suspend fun allValid(): Boolean = verify().values.all { it }
}
