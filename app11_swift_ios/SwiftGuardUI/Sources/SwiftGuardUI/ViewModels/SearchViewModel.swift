import Foundation
import SwiftData
import SwiftGuardData

@Observable
@MainActor
public final class SearchViewModel {
    public var queryText: String = ""
    public private(set) var results: [SearchResult] = []
    public private(set) var errorMessage: String?

    private let repository: SearchRepository
    private let localizationManager: LocalizationManager

    public init(modelContext: ModelContext, localizationManager: LocalizationManager) {
        self.repository = SwiftDataSearchRepository(modelContext: modelContext)
        self.localizationManager = localizationManager
    }

    public func search() {
        guard !queryText.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        do {
            results = try repository.query(queryText, locale: localizationManager.currentLocale)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
