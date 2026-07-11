import Foundation
import SwiftData

@MainActor
public final class SwiftDataFrameworkRepository: FrameworkRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func list() throws -> [Framework] {
        let descriptor = FetchDescriptor<Framework>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }

    public func detail(code: String) throws -> Framework? {
        var descriptor = FetchDescriptor<Framework>(predicate: #Predicate { $0.code == code })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
