import Foundation
import SwiftData

@MainActor
public final class SwiftDataMitigationRepository: MitigationRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func forThreat(code: String) throws -> [Mitigation] {
        let descriptor = FetchDescriptor<Mitigation>(predicate: #Predicate { $0.threat?.code == code })
        return try modelContext.fetch(descriptor)
    }

    public func forCard(cardId: String) throws -> [Mitigation] {
        let descriptor = FetchDescriptor<Mitigation>(predicate: #Predicate { $0.card?.cardId == cardId })
        return try modelContext.fetch(descriptor)
    }
}
