import Foundation
import SwiftData

@MainActor
public final class SwiftDataCardRepository: CardRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func bySuit(_ suitCode: String) throws -> [CornucopiaCard] {
        let upperSuit = suitCode.uppercased()
        let descriptor = FetchDescriptor<CornucopiaCard>(
            predicate: #Predicate { $0.suitCode == upperSuit },
            sortBy: [SortDescriptor(\.value)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func byEdition(_ edition: String) throws -> [CornucopiaCard] {
        let descriptor = FetchDescriptor<CornucopiaCard>(
            predicate: #Predicate { $0.edition == edition },
            sortBy: [SortDescriptor(\.suitCode), SortDescriptor(\.value)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func byCardId(_ cardId: String) throws -> CornucopiaCard? {
        var descriptor = FetchDescriptor<CornucopiaCard>(predicate: #Predicate { $0.cardId == cardId })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    public func suits(forEdition edition: String) throws -> [String] {
        let cards = try byEdition(edition)
        return Array(Set(cards.map(\.suitCode))).sorted()
    }
}
