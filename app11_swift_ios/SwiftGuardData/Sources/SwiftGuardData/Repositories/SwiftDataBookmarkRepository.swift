import Foundation
import SwiftData

@MainActor
public final class SwiftDataBookmarkRepository: BookmarkRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func add(code: String) throws {
        var descriptor = FetchDescriptor<Bookmark>(predicate: #Predicate { $0.threatOrCardCode == code })
        descriptor.fetchLimit = 1
        if try modelContext.fetch(descriptor).first != nil {
            return // already bookmarked, idempotent
        }
        modelContext.insert(Bookmark(threatOrCardCode: code))
        try modelContext.save()
    }

    public func remove(code: String) throws {
        let descriptor = FetchDescriptor<Bookmark>(predicate: #Predicate { $0.threatOrCardCode == code })
        for bookmark in try modelContext.fetch(descriptor) {
            modelContext.delete(bookmark)
        }
        try modelContext.save()
    }

    public func list() throws -> [Bookmark] {
        let descriptor = FetchDescriptor<Bookmark>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
}
