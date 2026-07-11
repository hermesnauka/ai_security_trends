package com.kotlinguard.data.model

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.PrimaryKey

@Entity(tableName = "frameworks")
data class FrameworkEntity(
    @PrimaryKey val code: String,          // "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS", ...
    val name: String,
    val version: String,
    val description: String,
    val referenceUrl: String
)

@Entity(tableName = "threats")
data class ThreatEntity(
    @PrimaryKey val code: String,          // "LLM01:2025", "A03:2021", "AML.T0051"
    val frameworkCode: String,
    val title: String,
    val severity: Severity,
    val category: String,
    val descriptionEn: String,
    val descriptionPl: String,              // content i18n lives on the entity directly, the
                                             // same single-device-store simplification app11
                                             // makes versus a separate translation table
    val attackVector: String,
    val attackSurface: String,
    val stride: List<StrideCategory>,       // Room TypeConverter, db/Converters.kt
    val tags: List<String>
) {
    /** FR-18.6-equivalent: falls back to English, never a blank field. */
    fun localizedDescription(locale: AppLocale): String =
        if (locale == AppLocale.POLISH && descriptionPl.isNotEmpty()) descriptionPl else descriptionEn
}

@Entity(tableName = "cards")
data class CornucopiaCardEntity(
    @PrimaryKey val cardId: String,        // "VE3", "LLM4", "SCO2"
    val suitCode: String,
    val suitName: String,
    val edition: String,                    // webapp, mobileapp, companion, eop, mlsec, dbd
    val value: String,                       // "2".."10","J","Q","K","A"
    val kind: CardKind,                       // D-03: TypeConverter-backed, db/Converters.kt
    val descriptionEn: String,
    val descriptionPl: String,
    val miscNote: String?,
    val sourceUrl: String?,
    val owaspRefs: List<String>,
    val mitreRefs: List<String>,
    val contentSha256: String,
    val isCritical: Boolean
) {
    fun localizedDescription(locale: AppLocale): String =
        if (locale == AppLocale.POLISH && descriptionPl.isNotEmpty()) descriptionPl else descriptionEn
}

@Entity(
    tableName = "mitigations",
    foreignKeys = [
        ForeignKey(entity = ThreatEntity::class, parentColumns = ["code"], childColumns = ["threatCode"]),
        ForeignKey(entity = CornucopiaCardEntity::class, parentColumns = ["cardId"], childColumns = ["cardId"])
    ]
)
data class MitigationEntity(
    @PrimaryKey val slug: String,
    val threatCode: String?,
    val cardId: String?,
    val title: String,
    val description: String,
    val mitigationType: MitigationType,
    val effort: Effort,
    val effectiveness: Effectiveness
    // non-emptiness of associated CodeSamples verified by a Kotest property over seed data,
    // not the type itself — the same accepted gap every sibling without a dedicated
    // NonEmpty-collection type states
)

@Entity(
    tableName = "code_samples",
    foreignKeys = [
        ForeignKey(entity = MitigationEntity::class, parentColumns = ["slug"], childColumns = ["mitigationSlug"])
    ]
)
data class CodeSampleEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val mitigationSlug: String,
    val language: CodeLanguage,
    val sampleType: SampleType,
    val title: String,
    val description: String,
    val code: String,
    val frameworkHint: String,   // "Room @Query", "Spring Boot 3.3", "Django ORM"...
    val versionNote: String
)

@Entity(tableName = "cross_references")
data class CrossReferenceEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val sourceThreatCode: String,
    val targetThreatCode: String,
    val targetThreatTitle: String,
    val relationshipType: RelationshipType,
    val description: String
)

@Entity(tableName = "content_hashes")
data class ContentHashEntity(
    @PrimaryKey val fileName: String,
    val sha256Hash: String,
    val verifiedAt: Long,   // epoch millis
    val isValid: Boolean,
    val verifiedBy: String = "kotlinguard-integrity-checker"
)

/** The only user-generated, sync-eligible data in this app (D-07). */
@Entity(tableName = "bookmarks")
data class BookmarkEntity(
    @PrimaryKey val threatOrCardCode: String,
    val createdAt: Long,
    val firestoreDocId: String? = null   // set only if Firestore sync (D-07) is enabled
)
