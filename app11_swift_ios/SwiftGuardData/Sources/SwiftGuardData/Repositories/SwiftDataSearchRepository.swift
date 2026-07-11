import Foundation
import SwiftData

/// FR-17.1-equivalent: SwiftData supports basic string predicates
/// (`localizedStandardContains`) but not a FULLTEXT/`MATCH...AGAINST`
/// engine — PLAN.md §6 Phase 6 states a lightweight on-device tokenized
/// index would be added if relevance needs improve beyond CONTAINS; that
/// index does not exist yet, so this is the plain-CONTAINS implementation.
@MainActor
public final class SwiftDataSearchRepository: SearchRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func query(_ text: String, locale: AppLocale) throws -> [SearchResult] {
        let threatDescriptor = FetchDescriptor<Threat>(
            predicate: #Predicate<Threat> {
                $0.title.localizedStandardContains(text) || $0.descriptionEn.localizedStandardContains(text)
            }
        )
        let threatResults = try modelContext.fetch(threatDescriptor).map { threat in
            SearchResult(
                code: threat.code,
                title: threat.title,
                excerpt: excerpt(from: threat.localizedDescription(locale), highlighting: text),
                kind: .threat
            )
        }

        let cardDescriptor = FetchDescriptor<CornucopiaCard>(
            predicate: #Predicate<CornucopiaCard> {
                $0.descriptionEn.localizedStandardContains(text) || $0.descriptionPl.localizedStandardContains(text)
            }
        )
        let cardResults = try modelContext.fetch(cardDescriptor).map { card in
            SearchResult(
                code: card.cardId,
                title: card.cardId,
                excerpt: excerpt(from: card.localizedDescription(locale), highlighting: text),
                kind: .card
            )
        }

        return threatResults + cardResults
    }

    private func excerpt(from text: String, highlighting term: String, contextChars: Int = 80) -> String {
        guard let range = text.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) else {
            return String(text.prefix(contextChars * 2))
        }
        let start = text.index(range.lowerBound, offsetBy: -contextChars, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: contextChars, limitedBy: text.endIndex) ?? text.endIndex
        return String(text[start..<end])
    }
}
