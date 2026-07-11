// PLAN.md §5.1 — core enums shared across the SwiftData model.

public enum Severity: String, Codable, Sendable {
    case critical, high, medium, low, info
}

public enum StrideCategory: String, Codable, Sendable {
    case s, t, r, i, d, e
}

public enum SampleType: String, Codable, Sendable {
    case attackDemo, defense
}

public enum CodeLanguage: String, Codable, Sendable, CaseIterable {
    case python, java, go, scala, lua
}

public enum MitigationType: String, Codable, Sendable {
    case preventive, detective, corrective, compensating
}

public enum Effort: String, Codable, Sendable {
    case low, medium, high
}

public enum Effectiveness: String, Codable, Sendable {
    case partial, significant, full
}

public enum RelationshipType: String, Codable, Sendable {
    case equivalent, related, parentChild, mapsTo
}

public enum AppLocale: String, Codable, Sendable {
    case polish = "pl"
    case english = "en"

    public var bundleIdentifier: String {
        rawValue
    }
}
