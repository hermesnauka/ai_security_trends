import Foundation
import SwiftData
import SwiftGuardData

@Observable
@MainActor
public final class ThreatBrowserViewModel {
    public var searchText: String = "" {
        didSet { scheduleFilter() }
    }
    public var selectedSeverity: Severity?
    public var selectedFrameworkCode: String?
    public private(set) var threats: [Threat] = []
    public private(set) var errorMessage: String?

    private let repository: ThreatRepository
    private var debounceTask: Task<Void, Never>?

    public init(modelContext: ModelContext, frameworkCode: String? = nil) {
        self.repository = SwiftDataThreatRepository(modelContext: modelContext)
        self.selectedFrameworkCode = frameworkCode
    }

    public func load() {
        applyFilter()
    }

    public func severityChanged() {
        applyFilter()
    }

    /// FR-02.4-equivalent: debounces at ~300ms, the same interval
    /// `threat-browser.js` used in app09 — the SwiftUI-native replacement
    /// for a JS debounce timer.
    private func scheduleFilter() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.applyFilter()
        }
    }

    private func applyFilter() {
        do {
            let filter = ThreatFilter(
                frameworkCode: selectedFrameworkCode,
                severity: selectedSeverity,
                query: searchText.isEmpty ? nil : searchText
            )
            threats = try repository.list(filter: filter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
