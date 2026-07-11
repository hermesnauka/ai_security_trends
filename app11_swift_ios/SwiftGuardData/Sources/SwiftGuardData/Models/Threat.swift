import Foundation
import SwiftData

@Model
public final class Threat {
    @Attribute(.unique) public var code: String        // "LLM01:2025", "A03:2021", "AML.T0051"
    public var title: String
    public var severity: Severity
    public var category: String
    public var descriptionEn: String
    public var descriptionPl: String                    // i18n content lives on the model directly —
                                                          // no separate translation table is needed since
                                                          // there is no multi-tenant/multi-row-per-locale
                                                          // concern on a single-device local store
    public var attackVector: String
    public var attackSurface: String
    public var stride: [StrideCategory]
    public var tags: [String]
    /// Inverse side of `Framework.threats` — SwiftData maintains both ends of
    /// this relationship together; setting one sets the other.
    public var framework: Framework?
    @Relationship(deleteRule: .cascade, inverse: \Mitigation.threat) public var mitigations: [Mitigation] = []

    public init(
        code: String,
        title: String,
        severity: Severity,
        category: String,
        descriptionEn: String,
        descriptionPl: String,
        attackVector: String,
        attackSurface: String,
        stride: [StrideCategory],
        tags: [String],
        framework: Framework? = nil
    ) {
        self.code = code
        self.title = title
        self.severity = severity
        self.category = category
        self.descriptionEn = descriptionEn
        self.descriptionPl = descriptionPl
        self.attackVector = attackVector
        self.attackSurface = attackSurface
        self.stride = stride
        self.tags = tags
        self.framework = framework
    }

    /// FR-18.6-equivalent: falls back to English when no Polish translation
    /// exists yet, never a blank field. `title`/`attackVector`/`attackSurface`
    /// are not localized in this schema (PLAN.md §5.3) — only the longer
    /// `description` field carries a Polish variant.
    public func localizedDescription(_ locale: AppLocale) -> String {
        locale == .polish && !descriptionPl.isEmpty ? descriptionPl : descriptionEn
    }
}
