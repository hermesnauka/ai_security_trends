package com.kotlinguard.data.seeding

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class FrameworkSeed(
    val code: String,
    val name: String,
    val version: String,
    val description: String,
    val referenceUrl: String
)

@Serializable
data class ThreatSeed(
    val frameworkCode: String,
    val code: String,
    val title: String,
    val severity: String,
    val category: String,
    val description: String,
    @SerialName("attack_vector") val attackVector: String,
    @SerialName("attack_surface") val attackSurface: String,
    val stride: String,
    val tags: List<String>
)

@Serializable
data class ThreatTranslationSeed(
    val code: String,
    val locale: String,
    val title: String,
    val description: String,
    @SerialName("attack_vector") val attackVector: String
)

@Serializable
data class CrossReferenceSeed(
    val sourceCode: String,
    val targetCode: String,
    val relationshipType: String,
    val description: String
)

@Serializable
data class MitigationSeed(
    val slug: String,
    val threatCode: String? = null,
    val cardId: String? = null,
    val title: String,
    val description: String,
    val mitigationType: String,
    val effort: String,
    val effectiveness: String
)

@Serializable
data class CodeSampleManifestEntry(
    val mitigationSlug: String,
    val language: String,
    val sampleType: String,
    val title: String,
    val description: String,
    val file: String,
    val frameworkHint: String,
    val versionNote: String
)
