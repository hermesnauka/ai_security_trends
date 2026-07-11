package com.kotlinguard.data.seeding

import com.kotlinguard.data.assets.AssetSource
import com.kotlinguard.data.cards.CardLoader
import com.kotlinguard.data.cards.ReferenceValidator
import com.kotlinguard.data.db.BookmarkDao
import com.kotlinguard.data.db.CardDao
import com.kotlinguard.data.db.CodeSampleDao
import com.kotlinguard.data.db.CrossReferenceDao
import com.kotlinguard.data.db.FrameworkDao
import com.kotlinguard.data.db.MitigationDao
import com.kotlinguard.data.db.ThreatDao
import com.kotlinguard.data.integrity.IntegrityChecker
import com.kotlinguard.data.model.CodeSampleEntity
import com.kotlinguard.data.model.CornucopiaCardEntity
import com.kotlinguard.data.model.CrossReferenceEntity
import com.kotlinguard.data.model.FrameworkEntity
import com.kotlinguard.data.model.MitigationEntity
import com.kotlinguard.data.model.StrideCategory
import com.kotlinguard.data.model.ThreatEntity
import kotlinx.serialization.json.Json

private inline fun <reified T : Enum<T>> enumFromRaw(raw: String): T? =
    enumValues<T>().find { it.name == raw.uppercase() }

/**
 * Called only on first launch / app-update (from the `:app` composition
 * root) and never from a ViewModel — mirrors app09's `Seed_Loader` +
 * `Card_Ingestion_Service` + `Mitigation_Seed_Loader` +
 * `Threat_Translation_Seed_Loader` + `Cross_Reference_Seed_Loader`, and
 * app11's `ContentSeeder`, folded into one type since there is no separate
 * activation-hook/cron split on a single-process client app.
 */
class ContentSeeder(
    private val assetSource: AssetSource,
    private val frameworkDao: FrameworkDao,
    private val threatDao: ThreatDao,
    private val cardDao: CardDao,
    private val mitigationDao: MitigationDao,
    private val codeSampleDao: CodeSampleDao,
    private val crossReferenceDao: CrossReferenceDao,
    private val integrityChecker: IntegrityChecker
) {
    private val json = Json { ignoreUnknownKeys = false }

    /** Idempotent, same as every seed step in app09/app11: safe to call on every launch, upserting rather than duplicating. */
    suspend fun seedIfNeeded() {
        seedFrameworks()
        seedThreats()
        seedThreatTranslations()
        seedCrossReferences()
        seedCards()
        seedMitigationsAndCodeSamples()
        integrityChecker.verify()
    }

    private suspend fun seedFrameworks() {
        val text = assetSource.readText("frameworks.json") ?: return
        val seeds = json.decodeFromString<List<FrameworkSeed>>(text)
        for (seed in seeds) {
            frameworkDao.upsert(
                FrameworkEntity(seed.code, seed.name, seed.version, seed.description, seed.referenceUrl)
            )
        }
    }

    private suspend fun seedThreats() {
        val text = assetSource.readText("threats_seed.json") ?: return
        val seeds = json.decodeFromString<List<ThreatSeed>>(text)
        for (seed in seeds) {
            if (threatDao.byCode(seed.code) != null) continue // threats are seeded once; edits happen via translations, not re-seeding
            val severity = enumFromRaw<com.kotlinguard.data.model.Severity>(seed.severity) ?: continue
            if (frameworkDao.byCode(seed.frameworkCode) == null) continue

            threatDao.insert(
                ThreatEntity(
                    code = seed.code,
                    frameworkCode = seed.frameworkCode,
                    title = seed.title,
                    severity = severity,
                    category = seed.category,
                    descriptionEn = seed.description,
                    descriptionPl = seed.description, // overwritten by seedThreatTranslations if a 'pl' row exists
                    attackVector = seed.attackVector,
                    attackSurface = seed.attackSurface,
                    stride = listOfNotNull(strideCategory(seed.stride)),
                    tags = seed.tags
                )
            )
        }
    }

    private suspend fun seedThreatTranslations() {
        val text = assetSource.readText("threat_translations_seed.json") ?: return
        val seeds = json.decodeFromString<List<ThreatTranslationSeed>>(text)
        for (seed in seeds.filter { it.locale == "pl" }) {
            val threat = threatDao.byCode(seed.code) ?: continue
            threatDao.update(threat.copy(descriptionPl = seed.description))
        }
    }

    private suspend fun seedCrossReferences() {
        val text = assetSource.readText("cross_references_seed.json") ?: return
        val seeds = json.decodeFromString<List<CrossReferenceSeed>>(text)
        for (seed in seeds) {
            val relationshipType = enumFromRaw<com.kotlinguard.data.model.RelationshipType>(seed.relationshipType) ?: continue
            val target = threatDao.byCode(seed.targetCode) ?: continue
            if (crossReferenceDao.exists(seed.sourceCode, seed.targetCode) > 0) continue

            crossReferenceDao.insert(
                CrossReferenceEntity(
                    sourceThreatCode = seed.sourceCode,
                    targetThreatCode = seed.targetCode,
                    targetThreatTitle = target.title,
                    relationshipType = relationshipType,
                    description = seed.description
                )
            )
        }
    }

    private suspend fun seedCards() {
        val referenceValidator = ReferenceValidator(assetSource)
        val loader = CardLoader(assetSource, referenceValidator)
        val seeds = loader.loadAll()

        for (seed in seeds) {
            cardDao.upsert(
                CornucopiaCardEntity(
                    cardId = seed.cardId,
                    suitCode = seed.suitCode,
                    suitName = seed.suitName,
                    edition = seed.edition,
                    value = seed.value,
                    kind = seed.kind,
                    descriptionEn = seed.descriptionEn,
                    descriptionPl = seed.descriptionPl,
                    miscNote = seed.miscNote,
                    sourceUrl = seed.sourceUrl,
                    owaspRefs = seed.owaspRefs,
                    mitreRefs = seed.mitreRefs,
                    contentSha256 = seed.contentSha256,
                    isCritical = seed.isCritical
                )
            )
        }
    }

    private suspend fun seedMitigationsAndCodeSamples() {
        val mitigationsText = assetSource.readText("mitigations_seed.json") ?: return
        val mitigationSeeds = json.decodeFromString<List<MitigationSeed>>(mitigationsText)

        for (seed in mitigationSeeds) {
            val type = enumFromRaw<com.kotlinguard.data.model.MitigationType>(seed.mitigationType) ?: continue
            val effort = enumFromRaw<com.kotlinguard.data.model.Effort>(seed.effort) ?: continue
            val effectiveness = enumFromRaw<com.kotlinguard.data.model.Effectiveness>(seed.effectiveness) ?: continue

            mitigationDao.upsert(
                MitigationEntity(
                    slug = seed.slug,
                    threatCode = seed.threatCode,
                    cardId = seed.cardId,
                    title = seed.title,
                    description = seed.description,
                    mitigationType = type,
                    effort = effort,
                    effectiveness = effectiveness
                )
            )
        }

        val manifestText = assetSource.readText("code_samples_manifest.json") ?: return
        val manifest = json.decodeFromString<List<CodeSampleManifestEntry>>(manifestText)

        for (entry in manifest) {
            if (mitigationDao.bySlug(entry.mitigationSlug) == null) continue
            val language = enumFromRaw<com.kotlinguard.data.model.CodeLanguage>(entry.language) ?: continue
            val sampleType = enumFromRaw<com.kotlinguard.data.model.SampleType>(entry.sampleType) ?: continue

            if (codeSampleDao.countExisting(entry.mitigationSlug, language.name, sampleType.name) > 0) continue

            val code = assetSource.readText("code_samples/${entry.file}") ?: continue

            codeSampleDao.insert(
                CodeSampleEntity(
                    mitigationSlug = entry.mitigationSlug,
                    language = language,
                    sampleType = sampleType,
                    title = entry.title,
                    description = entry.description,
                    code = code,
                    frameworkHint = entry.frameworkHint,
                    versionNote = entry.versionNote
                )
            )
        }
    }

    /**
     * Seed data stores STRIDE as the Cornucopia 2-letter suit code (SP, TA,
     * RE, ID, DS, EP), matching app09/app11's convention — mapped here to
     * this app's single-letter `StrideCategory` enum (PLAN.md §5.1).
     */
    private fun strideCategory(suitCode: String): StrideCategory? = when (suitCode) {
        "SP" -> StrideCategory.S
        "TA" -> StrideCategory.T
        "RE" -> StrideCategory.R
        "ID" -> StrideCategory.I
        "DS" -> StrideCategory.D
        "EP" -> StrideCategory.E
        else -> null
    }
}
