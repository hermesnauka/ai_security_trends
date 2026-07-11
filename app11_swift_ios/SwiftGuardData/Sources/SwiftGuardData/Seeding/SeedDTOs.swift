import Foundation

struct FrameworkSeed: Decodable {
    let code: String
    let name: String
    let version: String
    let description: String
    let referenceUrl: String
}

struct ThreatSeed: Decodable {
    let frameworkCode: String
    let code: String
    let title: String
    let severity: String
    let category: String
    let description: String
    let attackVector: String
    let attackSurface: String
    let stride: String
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case frameworkCode, code, title, severity, category, description, stride, tags
        case attackVector = "attack_vector"
        case attackSurface = "attack_surface"
    }
}

struct ThreatTranslationSeed: Decodable {
    let code: String
    let locale: String
    let title: String
    let description: String
    let attackVector: String

    enum CodingKeys: String, CodingKey {
        case code, locale, title, description
        case attackVector = "attack_vector"
    }
}

struct CrossReferenceSeed: Decodable {
    let sourceCode: String
    let targetCode: String
    let relationshipType: String
    let description: String
}

struct MitigationSeed: Decodable {
    let slug: String
    let threatCode: String?
    let cardId: String?
    let title: String
    let description: String
    let mitigationType: String
    let effort: String
    let effectiveness: String
}

struct CodeSampleManifestEntry: Decodable {
    let mitigationSlug: String
    let language: String
    let sampleType: String
    let title: String
    let description: String
    let file: String
    let frameworkHint: String
    let versionNote: String
}
