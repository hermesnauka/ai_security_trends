import Foundation
import SwiftData
import SwiftGuardData

/// Generic, parameterized by suit OR edition — the same "one view model,
/// many routes" pattern app09's suit-archive.php used, backing every
/// suit-browsing user story (US-05–US-12) with one type.
@Observable
@MainActor
public final class CardSuitViewModel {
    public private(set) var cards: [CornucopiaCard] = []
    public private(set) var errorMessage: String?

    private let repository: CardRepository

    public init(modelContext: ModelContext) {
        self.repository = SwiftDataCardRepository(modelContext: modelContext)
    }

    public func loadSuit(_ suitCode: String) {
        do {
            cards = try repository.bySuit(suitCode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func loadEdition(_ edition: String) {
        do {
            cards = try repository.byEdition(edition)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
