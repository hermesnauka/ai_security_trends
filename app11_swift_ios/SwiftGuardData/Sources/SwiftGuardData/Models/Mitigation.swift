import Foundation
import SwiftData

@Model
public final class Mitigation {
    @Attribute(.unique) public var slug: String
    public var title: String
    public var mitigationDescription: String
    public var mitigationType: MitigationType
    public var effort: Effort
    public var effectiveness: Effectiveness
    public var threat: Threat?
    public var card: CornucopiaCard?
    // non-emptiness of codeSamples verified by a SwiftCheck property over seed data,
    // not the type itself — [CodeSample] has no non-empty variant, the same accepted
    // gap every sibling without a dedicated NonEmpty type states
    @Relationship(deleteRule: .cascade, inverse: \CodeSample.mitigation) public var codeSamples: [CodeSample] = []

    public init(
        slug: String,
        title: String,
        mitigationDescription: String,
        mitigationType: MitigationType,
        effort: Effort,
        effectiveness: Effectiveness,
        threat: Threat? = nil,
        card: CornucopiaCard? = nil
    ) {
        self.slug = slug
        self.title = title
        self.mitigationDescription = mitigationDescription
        self.mitigationType = mitigationType
        self.effort = effort
        self.effectiveness = effectiveness
        self.threat = threat
        self.card = card
    }
}
