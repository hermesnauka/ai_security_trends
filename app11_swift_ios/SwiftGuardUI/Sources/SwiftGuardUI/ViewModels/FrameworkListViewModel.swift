import Foundation
import SwiftData
import SwiftGuardData

@Observable
@MainActor
public final class FrameworkListViewModel {
    public private(set) var frameworks: [Framework] = []
    public private(set) var errorMessage: String?

    private let repository: FrameworkRepository

    public init(modelContext: ModelContext) {
        self.repository = SwiftDataFrameworkRepository(modelContext: modelContext)
    }

    public func load() {
        do {
            frameworks = try repository.list()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
