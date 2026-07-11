import Foundation
import SwiftData

/// D-02: called only on first launch / app-update (from `SwiftGuardApp`'s
/// composition root) and never from a `ViewModel`. Mirrors app09's
/// `Seed_Loader` + `Card_Ingestion_Service` + `Mitigation_Seed_Loader` +
/// `Threat_Translation_Seed_Loader` + `Cross_Reference_Seed_Loader`, folded
/// into one type since there is no separate activation-hook/cron split on a
/// single-process client app.
public struct ContentSeeder: Sendable {
    private let bundle: Bundle
    private let integrityService: IntegrityService

    public init(bundle: Bundle = .main, integrityService: IntegrityService = IntegrityService()) {
        self.bundle = bundle
        self.integrityService = integrityService
    }

    @MainActor
    public func seedIfNeeded(modelContext: ModelContext) throws {
        // Idempotent, same as every seed step in app09: safe to call on every
        // launch, upserting rather than duplicating.
        try seedFrameworks(modelContext: modelContext)
        try seedThreats(modelContext: modelContext)
        try seedThreatTranslations(modelContext: modelContext)
        try seedCrossReferences(modelContext: modelContext)
        try seedCards(modelContext: modelContext)
        try seedMitigationsAndCodeSamples(modelContext: modelContext)
        _ = try integrityService.verify(modelContext: modelContext)
        try modelContext.save()
    }

    // MARK: - Frameworks

    @MainActor
    private func seedFrameworks(modelContext: ModelContext) throws {
        guard let url = bundle.url(forResource: "frameworks", withExtension: "json") else { return }
        let seeds = try JSONDecoder().decode([FrameworkSeed].self, from: Data(contentsOf: url))

        for seed in seeds {
            if let existing = try fetchFramework(code: seed.code, modelContext: modelContext) {
                existing.name = seed.name
                existing.version = seed.version
                existing.frameworkDescription = seed.description
                existing.referenceUrl = seed.referenceUrl
            } else {
                modelContext.insert(Framework(
                    code: seed.code, name: seed.name, version: seed.version,
                    frameworkDescription: seed.description, referenceUrl: seed.referenceUrl
                ))
            }
        }
    }

    // MARK: - Threats

    @MainActor
    private func seedThreats(modelContext: ModelContext) throws {
        guard let url = bundle.url(forResource: "threats_seed", withExtension: "json") else { return }
        let seeds = try JSONDecoder().decode([ThreatSeed].self, from: Data(contentsOf: url))

        for seed in seeds {
            if try fetchThreat(code: seed.code, modelContext: modelContext) != nil {
                continue // threats are seeded once; edits happen via translations, not re-seeding
            }
            guard let severity = Severity(rawValue: seed.severity),
                  let framework = try fetchFramework(code: seed.frameworkCode, modelContext: modelContext) else {
                continue
            }

            let threat = Threat(
                code: seed.code,
                title: seed.title,
                severity: severity,
                category: seed.category,
                descriptionEn: seed.description,
                descriptionPl: seed.description, // overwritten by seedThreatTranslations if a 'pl' row exists
                attackVector: seed.attackVector,
                attackSurface: seed.attackSurface,
                stride: [Self.strideCategory(fromSuitCode: seed.stride)].compactMap { $0 },
                tags: seed.tags,
                framework: framework
            )
            modelContext.insert(threat)
        }
    }

    @MainActor
    private func seedThreatTranslations(modelContext: ModelContext) throws {
        guard let url = bundle.url(forResource: "threat_translations_seed", withExtension: "json") else { return }
        let seeds = try JSONDecoder().decode([ThreatTranslationSeed].self, from: Data(contentsOf: url))

        for seed in seeds where seed.locale == "pl" {
            guard let threat = try fetchThreat(code: seed.code, modelContext: modelContext) else { continue }
            threat.descriptionPl = seed.description
        }
    }

    @MainActor
    private func seedCrossReferences(modelContext: ModelContext) throws {
        guard let url = bundle.url(forResource: "cross_references_seed", withExtension: "json") else { return }
        let seeds = try JSONDecoder().decode([CrossReferenceSeed].self, from: Data(contentsOf: url))

        for seed in seeds {
            guard let relationshipType = RelationshipType(rawValue: seed.relationshipType.camelCased()),
                  let target = try fetchThreat(code: seed.targetCode, modelContext: modelContext) else { continue }

            let descriptor = FetchDescriptor<CrossReference>(predicate: #Predicate<CrossReference> {
                $0.sourceThreatCode == seed.sourceCode && $0.targetThreatCode == seed.targetCode
            })
            if try modelContext.fetch(descriptor).first != nil { continue }

            modelContext.insert(CrossReference(
                sourceThreatCode: seed.sourceCode,
                targetThreatCode: seed.targetCode,
                targetThreatTitle: target.title,
                relationshipType: relationshipType,
                referenceDescription: seed.description
            ))
        }
    }

    // MARK: - Cards

    @MainActor
    private func seedCards(modelContext: ModelContext) throws {
        let referenceValidator = try ReferenceValidator(bundle: bundle)
        let loader = CardLoader(referenceValidator: referenceValidator, bundle: bundle)
        let seeds = try loader.loadAll()

        for seed in seeds {
            if let existing = try fetchCard(cardId: seed.cardId, modelContext: modelContext) {
                existing.contentSha256 = seed.contentSha256
                continue
            }
            modelContext.insert(CornucopiaCard(
                cardId: seed.cardId, suitCode: seed.suitCode, suitName: seed.suitName,
                edition: seed.edition, value: seed.value, kind: seed.kind,
                descriptionEn: seed.descriptionEn, descriptionPl: seed.descriptionPl,
                miscNote: seed.miscNote, sourceUrl: seed.sourceUrl,
                owaspRefs: seed.owaspRefs, mitreRefs: seed.mitreRefs,
                contentSha256: seed.contentSha256, isCritical: seed.isCritical
            ))
        }
    }

    // MARK: - Mitigations + code samples

    @MainActor
    private func seedMitigationsAndCodeSamples(modelContext: ModelContext) throws {
        guard let mitigationsUrl = bundle.url(forResource: "mitigations_seed", withExtension: "json") else { return }
        let mitigationSeeds = try JSONDecoder().decode([MitigationSeed].self, from: Data(contentsOf: mitigationsUrl))

        var mitigationsBySlug: [String: Mitigation] = [:]

        for seed in mitigationSeeds {
            guard let type = MitigationType(rawValue: seed.mitigationType),
                  let effort = Effort(rawValue: seed.effort),
                  let effectiveness = Effectiveness(rawValue: seed.effectiveness) else { continue }

            let threat = seed.threatCode.flatMap { try? fetchThreat(code: $0, modelContext: modelContext) } ?? nil
            let card = seed.cardId.flatMap { try? fetchCard(cardId: $0, modelContext: modelContext) } ?? nil

            let mitigation: Mitigation
            if let existing = try fetchMitigation(slug: seed.slug, modelContext: modelContext) {
                mitigation = existing
            } else {
                mitigation = Mitigation(
                    slug: seed.slug, title: seed.title, mitigationDescription: seed.description,
                    mitigationType: type, effort: effort, effectiveness: effectiveness,
                    threat: threat, card: card
                )
                modelContext.insert(mitigation)
            }
            mitigationsBySlug[seed.slug] = mitigation
        }

        guard let manifestUrl = bundle.url(forResource: "code_samples_manifest", withExtension: "json") else { return }
        let manifest = try JSONDecoder().decode([CodeSampleManifestEntry].self, from: Data(contentsOf: manifestUrl))

        for entry in manifest {
            guard let mitigation = mitigationsBySlug[entry.mitigationSlug],
                  let language = CodeLanguage(rawValue: entry.language),
                  let sampleType = SampleType(rawValue: entry.sampleType.camelCased()),
                  let codeUrl = bundle.url(forResource: (entry.file as NSString).lastPathComponent, withExtension: nil, subdirectory: "CodeSamples/\((entry.file as NSString).deletingLastPathComponent)") else {
                continue
            }

            let code = try String(contentsOf: codeUrl, encoding: .utf8)

            let alreadyExists = mitigation.codeSamples.contains { $0.language == language && $0.sampleType == sampleType }
            if alreadyExists { continue }

            let sample = CodeSample(
                language: language, sampleType: sampleType, title: entry.title,
                sampleDescription: entry.description, code: code,
                frameworkHint: entry.frameworkHint, versionNote: entry.versionNote,
                mitigation: mitigation
            )
            modelContext.insert(sample)
        }
    }

    // MARK: - Fetch helpers

    @MainActor
    private func fetchFramework(code: String, modelContext: ModelContext) throws -> Framework? {
        var descriptor = FetchDescriptor<Framework>(predicate: #Predicate { $0.code == code })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    @MainActor
    private func fetchThreat(code: String, modelContext: ModelContext) throws -> Threat? {
        var descriptor = FetchDescriptor<Threat>(predicate: #Predicate { $0.code == code })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    @MainActor
    private func fetchCard(cardId: String, modelContext: ModelContext) throws -> CornucopiaCard? {
        var descriptor = FetchDescriptor<CornucopiaCard>(predicate: #Predicate { $0.cardId == cardId })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    @MainActor
    private func fetchMitigation(slug: String, modelContext: ModelContext) throws -> Mitigation? {
        var descriptor = FetchDescriptor<Mitigation>(predicate: #Predicate { $0.slug == slug })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// Seed data stores STRIDE as the Cornucopia 2-letter suit code (SP, TA,
    /// RE, ID, DS, EP), matching app09's convention — mapped here to this
    /// app's single-letter `StrideCategory` enum (PLAN.md §5.1).
    private static func strideCategory(fromSuitCode code: String) -> StrideCategory? {
        switch code {
        case "SP": return .s
        case "TA": return .t
        case "RE": return .r
        case "ID": return .i
        case "DS": return .d
        case "EP": return .e
        default: return nil
        }
    }
}

private extension String {
    /// "attack_demo" -> "attackDemo", "parent_child" -> "parentChild" — the
    /// seed JSON's snake_case enum-value strings need to match Swift's
    /// camelCase `RawRepresentable` enum cases.
    func camelCased() -> String {
        let parts = split(separator: "_")
        guard let first = parts.first else { return self }
        return ([String(first)] + parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }).joined()
    }
}
