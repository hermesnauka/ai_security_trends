import SwiftData
import SwiftUI
import SwiftGuardData

public struct FrameworkListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FrameworkListViewModel?

    public init() {}

    public var body: some View {
        NavigationStack {
            List(viewModel?.frameworks ?? []) { framework in
                NavigationLink(value: framework.code) {
                    VStack(alignment: .leading) {
                        Text(framework.name).font(.headline)
                        Text(framework.version).font(.caption).foregroundStyle(.secondary)
                        Text(framework.frameworkDescription).font(.subheadline).lineLimit(2)
                    }
                }
                .accessibilityIdentifier("framework-row-\(framework.code)")
            }
            .navigationTitle("Frameworki Bezpieczeństwa")
            .navigationDestination(for: String.self) { frameworkCode in
                ThreatBrowserView(frameworkCode: frameworkCode)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { LanguageToggleView() }
            }
            .task {
                if viewModel == nil {
                    viewModel = FrameworkListViewModel(modelContext: modelContext)
                }
                viewModel?.load()
            }
        }
    }
}
