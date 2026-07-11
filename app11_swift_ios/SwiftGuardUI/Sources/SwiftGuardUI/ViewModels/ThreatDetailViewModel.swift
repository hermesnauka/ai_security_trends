import Foundation
import SwiftData
import SwiftGuardData

@Observable
@MainActor
public final class ThreatDetailViewModel {
    public private(set) var threat: Threat?
    public private(set) var mitigations: [Mitigation] = []
    public private(set) var crossReferences: [CrossReference] = []
    public private(set) var errorMessage: String?

    private let threatRepository: ThreatRepository
    private let mitigationRepository: MitigationRepository

    public init(modelContext: ModelContext) {
        self.threatRepository = SwiftDataThreatRepository(modelContext: modelContext)
        self.mitigationRepository = SwiftDataMitigationRepository(modelContext: modelContext)
    }

    public func load(threatCode: String) {
        do {
            threat = try threatRepository.detail(code: threatCode)
            mitigations = try mitigationRepository.forThreat(code: threatCode)
            crossReferences = try threatRepository.crossReferences(sourceCode: threatCode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
