import Foundation
import SwiftData

/// D-04: every filter is expressed as a single `#Predicate`, compile-time
/// checked against `Threat`'s actual properties — there is no string-based
/// query-construction path, so the "nil means match everything" pattern
/// below is expressed as `filter == nil || property == filter!` inside one
/// macro-expanded expression rather than composed at runtime the way an
/// `NSPredicate`/SQL query builder would.
@MainActor
public final class SwiftDataThreatRepository: ThreatRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func list(filter: ThreatFilter) throws -> [Threat] {
        let frameworkCode = filter.frameworkCode
        let severity = filter.severity
        let category = filter.category
        let stride = filter.stride
        let tag = filter.tag
        let query = filter.query

        let predicate = #Predicate<Threat> { threat in
            (frameworkCode == nil || threat.framework?.code == frameworkCode)
                && (severity == nil || threat.severity == severity)
                && (category == nil || threat.category == category)
                && (stride == nil || threat.stride.contains(stride!))
                && (tag == nil || threat.tags.contains(tag!))
                && (query == nil
                    || threat.title.localizedStandardContains(query!)
                    || threat.descriptionEn.localizedStandardContains(query!))
        }

        var descriptor = FetchDescriptor<Threat>(predicate: predicate, sortBy: [SortDescriptor(\.code)])
        descriptor.sortBy = [SortDescriptor(\.code)]
        let results = try modelContext.fetch(descriptor)

        // Severity ordering (critical first) isn't expressible as a stored
        // SortDescriptor over a String-backed enum without a helper column,
        // so it's applied in-memory after the compile-time-checked fetch.
        let severityOrder: [Severity: Int] = [.critical: 0, .high: 1, .medium: 2, .low: 3, .info: 4]
        return results.sorted { (severityOrder[$0.severity] ?? 99) < (severityOrder[$1.severity] ?? 99) }
    }

    public func detail(code: String) throws -> Threat? {
        var descriptor = FetchDescriptor<Threat>(predicate: #Predicate { $0.code == code })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    public func crossReferences(sourceCode: String) throws -> [CrossReference] {
        let descriptor = FetchDescriptor<CrossReference>(predicate: #Predicate { $0.sourceThreatCode == sourceCode })
        return try modelContext.fetch(descriptor)
    }
}
